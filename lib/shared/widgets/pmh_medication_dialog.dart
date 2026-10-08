import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ── Suggested medications per condition ──────────────────────────────────────
const Map<String, List<String>> _conditionSuggestions = {
  'Hypertension': [
    'Losartan',
    'Amlodipine',
    'Enalapril',
    'Metoprolol',
    'Hydrochlorothiazide',
    'Valsartan',
    'Ramipril',
    'Carvedilol',
    'Lisinopril',
    'Bisoprolol',
  ],
  'Diabetes Mellitus': [
    'Metformin',
    'Glibenclamide',
    'Gliclazide',
    'Insulin (Regular)',
    'Insulin (NPH)',
    'Sitagliptin',
    'Empagliflozin',
    'Pioglitazone',
    'Dapagliflozin',
  ],
  'Glaucoma': [
    'Timolol Eye Drops',
    'Latanoprost Eye Drops',
    'Brimonidine Eye Drops',
    'Dorzolamide Eye Drops',
    'Bimatoprost Eye Drops',
    'Betaxolol Eye Drops',
    'Travoprost Eye Drops',
  ],
  'Allergies': [
    'Cetirizine',
    'Loratadine',
    'Diphenhydramine',
    'Fexofenadine',
    'Montelukast',
    'Desloratadine',
    'Ebastine',
  ],
  'Operations': [
    'No specific medications',
  ],
  'Medications': [], // free-text list only
};

List<String> getSuggestions(String condition) =>
    _conditionSuggestions[condition] ?? [];

/// Reusable bottom-sheet dialog for capturing medications linked to a PMH condition.
///
/// Usage:
/// ```dart
/// final result = await showPmhMedicationDialog(
///   context,
///   conditionName: 'Hypertension',
///   existingMeds: ['Losartan'],
///   isDark: isDark,
/// );
/// // result == null → user dismissed/skipped; result == [] → cleared
/// ```
Future<List<String>?> showPmhMedicationDialog(
  BuildContext context, {
  required String conditionName,
  required List<String> existingMeds,
  required bool isDark,
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _PmhMedicationSheet(
      conditionName: conditionName,
      existingMeds: existingMeds,
      isDark: isDark,
    ),
  );
}

class _PmhMedicationSheet extends StatefulWidget {
  final String conditionName;
  final List<String> existingMeds;
  final bool isDark;

  const _PmhMedicationSheet({
    required this.conditionName,
    required this.existingMeds,
    required this.isDark,
  });

  @override
  State<_PmhMedicationSheet> createState() => _PmhMedicationSheetState();
}

class _PmhMedicationSheetState extends State<_PmhMedicationSheet> {
  late List<String> _meds;
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _meds = List.from(widget.existingMeds);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addMed(String med) {
    final trimmed = med.trim();
    if (trimmed.isEmpty) return;
    if (_meds.any((m) => m.toLowerCase() == trimmed.toLowerCase())) return;
    setState(() => _meds.add(trimmed));
    _inputCtrl.clear();
    _focusNode.requestFocus();
  }

  void _removeMed(String med) => setState(() => _meds.remove(med));

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF131D31) : Colors.white;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final surfaceMid = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final border = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    final suggestions = getSuggestions(widget.conditionName);

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceHover : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medications for',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.conditionName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: subtitleColor, size: 20),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: border),

          // ── Scrollable Content ────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Current medication chips ──────────────────────────────
                  if (_meds.isNotEmpty) ...[
                    Text(
                      'Current Medications',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: subtitleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _meds
                          .map(
                            (m) => Chip(
                              label: Text(m),
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              backgroundColor: const Color(0xFF7C3AED),
                              deleteIconColor:
                                  Colors.white.withValues(alpha: 0.8),
                              onDeleted: () => _removeMed(m),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Text input ────────────────────────────────────────────
                  Text(
                    'Add Medication',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: subtitleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type medication name...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textDisabled
                                  : AppColors.lightTextDisabled,
                            ),
                            filled: true,
                            fillColor: surfaceMid,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7C3AED), width: 1.8),
                            ),
                          ),
                          onSubmitted: _addMed,
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AddButton(
                        onPressed: () => _addMed(_inputCtrl.text),
                      ),
                    ],
                  ),

                  // ── Suggestions ───────────────────────────────────────────
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Quick-Add Suggestions',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: subtitleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions
                          .where((s) => !_meds
                              .any((m) => m.toLowerCase() == s.toLowerCase()))
                          .map(
                            (s) => ActionChip(
                              label: Text(s),
                              labelStyle: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.primarySoft
                                    : AppColors.primary,
                              ),
                              avatar: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.primarySoft
                                    : AppColors.primary,
                              ),
                              backgroundColor: isDark
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.primarySoft
                                          .withValues(alpha: 0.3)
                                      : AppColors.primary
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                              onPressed: () => _addMed(s),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Footer Buttons ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            child: Row(
              children: [
                // Skip
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtitleColor,
                      side: BorderSide(color: border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _meds),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _meds.isEmpty
                          ? 'Confirm (None)'
                          : 'Save ${_meds.length} Med${_meds.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
      );
}
