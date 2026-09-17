import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/annotation.dart';
import '../../data/models/clinical_examination.dart';
import '../../providers/nurse_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/drawing_canvas.dart';

/// Clinical Medical Drawing Screen — Diagram Annotations, Tools & Cloud Save
class NurseDrawingScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String examType;
  final String department;
  final String? queueNumber;
  final String? queueEntryId;
  final String? examinationUuid;
  final dynamic savedDiagram; // List of ClinicalExamination or Maps
  final bool viewMode;
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory;

  const NurseDrawingScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.examType,
    required this.department,
    this.queueNumber,
    this.queueEntryId,
    this.examinationUuid,
    this.savedDiagram,
    this.viewMode = false,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
  });

  @override
  State<NurseDrawingScreen> createState() => _NurseDrawingScreenState();
}

class _NurseDrawingScreenState extends State<NurseDrawingScreen> {
  late DrawingTool _currentTool;
  late Color _currentColor;
  late double _strokeWidth;
  late String _currentView;
  final Map<String, List<Annotation>> _annotationsByView = {};

  final GlobalKey _repaintKey = GlobalKey();
  final Map<String, GlobalKey<DrawingCanvasState>> _canvasKeys = {};
  GlobalKey<DrawingCanvasState> get _currentCanvasKey {
    if (!_canvasKeys.containsKey(_currentView)) {
      _canvasKeys[_currentView] = GlobalKey<DrawingCanvasState>();
    }
    return _canvasKeys[_currentView]!;
  }

  final TextEditingController _notesController = TextEditingController();
  final TransformationController _transformationController = TransformationController();

  bool _isSaving = false;
  bool _isNotesPanelOpen = false;
  Size _viewportSize = Size.zero;

  // Medical drawing preset colors
  final List<Color> _presetColors = const [
    Color(0xFFEF4444), // Crimson Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFF1E293B), // Charcoal
  ];

  static const double _contentWidth = 3600.0;
  static const double _contentHeight = 2800.0;

  double get _fitScale {
    if (_viewportSize == Size.zero) return 0.25;
    final sx = _viewportSize.width / _contentWidth;
    final sy = _viewportSize.height / _contentHeight;
    return sx < sy ? sx : sy;
  }

  List<String> _getAvailableViews() {
    final lower = widget.examType.toLowerCase();
    final List<String> views;
    switch (lower) {
      case 'eye':
      case 'eyes':
        views = ['1', '2', '3'];
        break;
      case 'ear':
      case 'ears':
        views = ['1', '2', '3'];
        break;
      case 'nose':
        views = ['1'];
        break;
      case 'throat':
        views = ['1', '2', '3'];
        break;
      case 'neck':
        views = ['1'];
        break;
      case 'head':
        views = ['1', '2'];
        break;
      case 'drawing':
      default:
        views = [];
        break;
    }
    views.add('drawing');
    return views;
  }

  @override
  void initState() {
    super.initState();
    final availableViews = _getAvailableViews();
    _currentView = availableViews.first;
    _currentTool = widget.viewMode ? DrawingTool.pan : DrawingTool.freehand;
    _currentColor = const Color(0xFFEF4444);
    _strokeWidth = 4.0;

    for (final v in availableViews) {
      _annotationsByView[v] = [];
    }

    _loadExistingDiagram();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetZoom();
    });
  }

  void _loadExistingDiagram() {
    if (widget.savedDiagram == null) return;
    try {
      final List<dynamic> items = widget.savedDiagram is List
          ? widget.savedDiagram
          : [widget.savedDiagram];

      for (final item in items) {
        if (item is ClinicalExamination) {
          _annotationsByView[item.viewName] = List.from(item.annotations);
          if (item.clinicalFindings != null && item.clinicalFindings!.isNotEmpty) {
            _notesController.text = item.clinicalFindings!;
          }
        } else if (item is Map<String, dynamic>) {
          final viewName = item['view_name']?.toString() ?? '1';
          final exam = ClinicalExamination.fromJson(item);
          _annotationsByView[viewName] = List.from(exam.annotations);
          if (exam.clinicalFindings != null && exam.clinicalFindings!.isNotEmpty) {
            _notesController.text = exam.clinicalFindings!;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading existing diagram annotations: $e');
    }
  }

  List<String> _getDiagramPathsForView(String view) {
    if (view == 'drawing') return [];

    final examLower = widget.examType.toLowerCase();
    final capitalized = examLower[0].toUpperCase() + examLower.substring(1);

    if (examLower == 'eyes' || examLower == 'eye') {
      final names = ['GrossExam', 'Fundoscopy', 'Biomicroscopy'];
      final idx = (int.tryParse(view) ?? 1) - 1;
      final safeIdx = idx.clamp(0, names.length - 1);
      final examName = names[safeIdx];
      return [
        'assets/diagrams/$examName-left.png',
        'assets/diagrams/$examName-right.png',
      ];
    }

    final isPairedEars = (examLower == 'ears' || examLower == 'ear') && view != '3';
    if (isPairedEars) {
      return [
        'assets/diagrams/$capitalized-$view-left.png',
        'assets/diagrams/$capitalized-$view-right.png',
      ];
    } else {
      final soloPath = 'assets/diagrams/$capitalized-$view-solo.png';
      return [soloPath, soloPath];
    }
  }

  void _switchView(String newView) {
    if (_currentView == newView) return;
    // Save current canvas annotations
    if (_currentCanvasKey.currentState != null) {
      _annotationsByView[_currentView] = List.from(_currentCanvasKey.currentState!.annotations);
    }
    setState(() {
      _currentView = newView;
    });
  }

  void _resetZoom() {
    if (_viewportSize == Size.zero) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    final scale = _fitScale * 1.35;
    final sw = _contentWidth * scale;
    final sh = _contentHeight * scale;

    final matrix = Matrix4.identity()
      ..translateByDouble(
        (_viewportSize.width - sw) / 2,
        (_viewportSize.height - sh) / 2,
        0.0,
        1.0,
      )
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    _transformationController.value = matrix;
  }

  void _zoom(double factor) {
    if (_viewportSize == Size.zero) return;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = currentScale * factor;
    if (newScale < _fitScale * 0.3 || newScale > _fitScale * 12.0) return;

    final fx = _viewportSize.width / 2;
    final fy = _viewportSize.height / 2;

    final zoom = Matrix4.identity()
      ..translateByDouble(fx, fy, 0.0, 1.0)
      ..scaleByDouble(factor, factor, 1.0, 1.0)
      ..translateByDouble(-fx, -fy, 0.0, 1.0);

    _transformationController.value = zoom * _transformationController.value;
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clinical Annotation Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (c) => setState(() => _currentColor = c),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPng() async {
    try {
      final nurseProv = context.read<NurseProvider>();
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final filename = 'diagram_${widget.examType}_${DateTime.now().millisecondsSinceEpoch}';
      final path = await nurseProv.exportImageToFile(bytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path.isNotEmpty ? 'Diagram exported to $path' : 'Diagram image captured'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveToServer() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 1. Commit current canvas annotations
      if (_currentCanvasKey.currentState != null) {
        _annotationsByView[_currentView] = List.from(_currentCanvasKey.currentState!.annotations);
      }

      final nurseProv = context.read<NurseProvider>();
      final String sessionUuid = widget.examinationUuid ?? const Uuid().v4();
      final availableViews = _getAvailableViews();

      // 2. Capture PNG for current view
      Uint8List? currentViewPngBytes;
      try {
        final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          currentViewPngBytes = byteData?.buffer.asUint8List();
        }
      } catch (e) {
        debugPrint('Error rendering PNG for upload: $e');
      }

      String? uploadedImageUrl;
      if (currentViewPngBytes != null) {
        uploadedImageUrl = await nurseProv.uploadDiagramImage(
          examinationUuid: sessionUuid,
          viewName: _currentView,
          bytes: currentViewPngBytes,
        );
      }

      // 3. Build ClinicalExamination records for all views that have annotations or for all available views
      final List<ClinicalExamination> examinationRecords = [];
      for (final view in availableViews) {
        final viewAnnotations = _annotationsByView[view] ?? [];
        examinationRecords.add(
          ClinicalExamination(
            id: const Uuid().v4(),
            examinationUuid: sessionUuid,
            patientId: widget.patientId,
            queueEntryId: widget.queueEntryId,
            department: widget.department,
            examType: widget.examType.toUpperCase(),
            viewName: view,
            annotations: viewAnnotations,
            imageUrl: view == _currentView ? uploadedImageUrl : null,
            clinicalFindings: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            deviceInfo: 'OLOF Clinical Station ($view)',
          ),
        );
      }

      final success = await nurseProv.saveExaminationBatch(examinationRecords);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinical diagram examination saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        throw Exception(nurseProv.errorMessage ?? 'Save failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving examination: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final availableViews = _getAvailableViews();

    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final currentAnnotations = _annotationsByView[_currentView] ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────────────
            // TOP HEADER BAR
            // ─────────────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: subtitleColor),
                    tooltip: 'Back to Exams',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${widget.patientName} — ${widget.examType.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.viewMode
                                    ? AppColors.cyanCalm.withValues(alpha: 0.15)
                                    : const Color(0xFFEC4899).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.viewMode ? 'VIEW MODE' : 'ANNOTATION MODE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: widget.viewMode ? AppColors.cyanCalm : const Color(0xFFEC4899),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'View $_currentView (${_getViewLabel(_currentView)}) • Annotations: ${currentAnnotations.length}',
                          style: TextStyle(fontSize: 11.5, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),

                  // View Selector Segments
                  if (availableViews.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDarkest : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: availableViews.map((v) {
                            final isSelected = v == _currentView;
                            return InkWell(
                              onTap: () => _switchView(v),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEC4899) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  v == 'drawing' ? 'Blank' : 'View $v',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Notes Toggle Button
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _notesController.text.isNotEmpty,
                      child: Icon(
                        _isNotesPanelOpen ? Icons.notes_rounded : Icons.description_outlined,
                        color: _isNotesPanelOpen ? const Color(0xFFEC4899) : subtitleColor,
                      ),
                    ),
                    tooltip: 'Nurse Clinical Findings',
                    onPressed: () => setState(() => _isNotesPanelOpen = !_isNotesPanelOpen),
                  ),

                  // Export PNG
                  IconButton(
                    icon: Icon(Icons.download_rounded, color: subtitleColor),
                    tooltip: 'Export PNG',
                    onPressed: _exportPng,
                  ),

                  // Save to Cloud Button
                  if (!widget.viewMode)
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveToServer,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save to Cloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────────────────────
            // MAIN WORKSPACE (TOOLBAR + CANVAS + CLINICAL NOTES DRAWER)
            // ─────────────────────────────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Left Tools Palette (If not view mode)
                  if (!widget.viewMode)
                    _buildToolsSidebar(isDark),

                  // Interactive Drawing Canvas Area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportSize = constraints.biggest;
                        return Container(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: _fitScale * 0.25,
                            maxScale: _fitScale * 12.0,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            constrained: false,
                            panEnabled: _currentTool == DrawingTool.pan || widget.viewMode,
                            scaleEnabled: _currentTool == DrawingTool.pan || widget.viewMode,
                            child: Container(
                              padding: const EdgeInsets.all(120),
                              child: RepaintBoundary(
                                key: _repaintKey,
                                child: Container(
                                  width: _contentWidth,
                                  height: _contentHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 30,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: DrawingCanvas(
                                    key: _currentCanvasKey,
                                    diagramPaths: _getDiagramPathsForView(_currentView),
                                    initialAnnotations: _annotationsByView[_currentView] ?? [],
                                    onAnnotationsChanged: (updatedList) {
                                      _annotationsByView[_currentView] = updatedList;
                                    },
                                    currentTool: _currentTool,
                                    currentColor: _currentColor,
                                    strokeWidth: _strokeWidth,
                                    currentExamType: widget.examType,
                                    readOnly: widget.viewMode || _isSaving,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Collapsible Clinical Notes Panel
                  if (_isNotesPanelOpen)
                    _buildNotesDrawer(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getViewLabel(String view) {
    if (view == 'drawing') return 'Blank Canvas';
    final lower = widget.examType.toLowerCase();
    if (lower == 'eyes' || lower == 'eye') {
      if (view == '1') return 'Gross Exam';
      if (view == '2') return 'Fundoscopy';
      if (view == '3') return 'Biomicroscopy';
    }
    return 'View $view';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOOLS SIDEBAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildToolsSidebar(bool isDark) {
    final bg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Container(
      width: 74,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 1.2)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            // Freehand Pen
            _buildToolIcon(
              tool: DrawingTool.freehand,
              icon: Icons.edit_rounded,
              label: 'Pen',
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // Circle Annotation
            _buildToolIcon(
              tool: DrawingTool.circle,
              icon: Icons.circle_outlined,
              label: 'Circle',
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // Marker Point
            _buildToolIcon(
              tool: DrawingTool.marker,
              icon: Icons.place_rounded,
              label: 'Marker',
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // Pan & Zoom
            _buildToolIcon(
              tool: DrawingTool.pan,
              icon: Icons.pan_tool_rounded,
              label: 'Pan',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 12),

            // Active Color Swatch & Presets
            InkWell(
              onTap: _pickColor,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Color', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),
            // Quick preset palette
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _presetColors.map((c) {
                final isSelected = c.toARGB32() == _currentColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _currentColor = c),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 10),

            // Stroke Width
            Text('${_strokeWidth.toInt()} px',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
            RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _strokeWidth,
                min: 1.0,
                max: 10.0,
                activeColor: const Color(0xFFEC4899),
                onChanged: (val) => setState(() => _strokeWidth = val),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 8),

            // Undo
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 20),
              tooltip: 'Undo Last Annotation',
              onPressed: () {
                _currentCanvasKey.currentState?.undo();
              },
            ),

            // Clear
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
              tooltip: 'Clear View Annotations',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear View Annotations?'),
                    content: const Text('This will clear all marks drawn on this specific view.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _currentCanvasKey.currentState?.clear();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),

            Divider(color: borderColor, height: 1),
            const SizedBox(height: 8),

            // Zoom In / Out / Reset
            IconButton(
              icon: const Icon(Icons.zoom_in_rounded, size: 20),
              tooltip: 'Zoom In',
              onPressed: () => _zoom(1.25),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out_rounded, size: 20),
              tooltip: 'Zoom Out',
              onPressed: () => _zoom(0.8),
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen_rounded, size: 20),
              tooltip: 'Reset Fit',
              onPressed: _resetZoom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolIcon({
    required DrawingTool tool,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentTool == tool;
    return InkWell(
      onTap: () => setState(() => _currentTool = tool),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC4899) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CLINICAL NOTES & FINDINGS DRAWER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotesDrawer(bool isDark) {
    final bg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.lightBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notes_rounded, color: Color(0xFFEC4899), size: 19),
                    const SizedBox(width: 8),
                    Text(
                      'Clinical Findings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() => _isNotesPanelOpen = false),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receptionist Intake Details
                  if ((widget.chiefComplaint != null && widget.chiefComplaint!.isNotEmpty) ||
                      (widget.historyOfPresentIllness != null && widget.historyOfPresentIllness!.isNotEmpty) ||
                      (widget.pastMedicalHistory != null && widget.pastMedicalHistory!.isNotEmpty)) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Color(0xFFEC4899)),
                              const SizedBox(width: 5),
                              const Text(
                                'RECEPTIONIST INTAKE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEC4899),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          if (widget.chiefComplaint != null && widget.chiefComplaint!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 11.5, color: titleColor),
                                children: [
                                  const TextSpan(
                                    text: 'Chief Complaint: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEC4899)),
                                  ),
                                  TextSpan(text: widget.chiefComplaint!),
                                ],
                              ),
                            ),
                          ],
                          if (widget.historyOfPresentIllness != null && widget.historyOfPresentIllness!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 11.5, color: titleColor),
                                children: [
                                  TextSpan(
                                    text: 'HPI: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: subtitleColor),
                                  ),
                                  TextSpan(text: widget.historyOfPresentIllness!),
                                ],
                              ),
                            ),
                          ],
                          if (widget.pastMedicalHistory != null && widget.pastMedicalHistory!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 11.5, color: titleColor),
                                children: [
                                  const TextSpan(
                                    text: 'PMH: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanCalm),
                                  ),
                                  TextSpan(text: widget.pastMedicalHistory!),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  Text(
                    'Document anatomical findings, lesions, observations or patient complaints below. These notes will be saved alongside this examination diagram.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _notesController,
                    maxLines: 12,
                    style: TextStyle(fontSize: 13.5, color: titleColor),
                    decoration: InputDecoration(
                      hintText: 'Enter clinical observations, anatomical notes, or findings...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEC4899), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'QUICK CLINICAL TAGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Normal findings',
                      'Inflammation noted',
                      'Mild discharge',
                      'Lesion detected',
                      'Foreign body',
                      'Pain on palpation',
                      'Follow-up in 1 wk',
                    ].map((tag) {
                      return ActionChip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                        side: BorderSide(color: borderColor),
                        onPressed: () {
                          final current = _notesController.text.trim();
                          if (current.isEmpty) {
                            _notesController.text = tag;
                          } else {
                            _notesController.text = '$current • $tag';
                          }
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
