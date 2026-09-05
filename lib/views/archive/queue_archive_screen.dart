import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/queue_entry.dart';
import '../../providers/queue_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/olof_logo.dart';

/// Screen displaying historical / archived queue entries with date and purpose
class QueueArchiveScreen extends StatefulWidget {
  const QueueArchiveScreen({super.key});

  @override
  State<QueueArchiveScreen> createState() => _QueueArchiveScreenState();
}

class _QueueArchiveScreenState extends State<QueueArchiveScreen> {
  String _selectedDateKey = 'ALL';
  String _selectedDepartment = 'ALL';
  String _selectedStatus = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  List<QueueEntry> _entries = [];
  List<String> _availableDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchiveData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchiveData() async {
    setState(() => _isLoading = true);
    final queueProv = context.read<QueueProvider>();

    try {
      final dates = await queueProv.getArchiveDates();
      final entries = await queueProv.getArchivedEntries(
        dateKey: _selectedDateKey == 'ALL' ? null : _selectedDateKey,
        department: _selectedDepartment == 'ALL' ? null : _selectedDepartment,
        searchQuery: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _availableDates = dates;
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<QueueEntry> get _filteredEntries {
    if (_selectedStatus == 'ALL') return _entries;
    return _entries.where((e) => e.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    final bgColor = isDark ? AppColors.surfaceDarkest : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.surfaceGradient
              : AppColors.lightSurfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, isCompact),
              _buildFilterBar(context, isDark, isCompact),
              _buildStatsSummary(context, isDark, isCompact),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildArchiveList(context, isDark, isCompact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isCompact) {
    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/secretary');
              }
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'QUEUE ARCHIVE',
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 19,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PAST LOGS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Historical patients by date, department, consultation purpose & doctor',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12.5,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadArchiveData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Archive',
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isDark, bool isCompact) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _loadArchiveData(),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, ticket #, purpose, or doctor...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _loadArchiveData();
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Date picker / selector
              _buildDateDropdown(isDark),
            ],
          ),
          const SizedBox(height: 10),
          // Department & Status Filters
          Row(
            children: [
              Text(
                'Dept:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _buildFilterChip('ALL', 'All', _selectedDepartment, (v) {
                setState(() => _selectedDepartment = v);
                _loadArchiveData();
              }, isDark),
              const SizedBox(width: 6),
              _buildFilterChip('ENT', 'ENT', _selectedDepartment, (v) {
                setState(() => _selectedDepartment = v);
                _loadArchiveData();
              }, isDark, color: AppColors.entColor),
              const SizedBox(width: 6),
              _buildFilterChip('EYES', 'Eyes', _selectedDepartment, (v) {
                setState(() => _selectedDepartment = v);
                _loadArchiveData();
              }, isDark, color: AppColors.eyesColor),
              const Spacer(),
              Text(
                'Status:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _buildFilterChip('ALL', 'All', _selectedStatus, (v) {
                setState(() => _selectedStatus = v);
              }, isDark),
              const SizedBox(width: 6),
              _buildFilterChip('completed', 'Done', _selectedStatus, (v) {
                setState(() => _selectedStatus = v);
              }, isDark, color: AppColors.success),
              const SizedBox(width: 6),
              _buildFilterChip('skipped', 'Skip', _selectedStatus, (v) {
                setState(() => _selectedStatus = v);
              }, isDark, color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateDropdown(bool isDark) {
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    final dateOptions = ['ALL', ..._availableDates];

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dateOptions.contains(_selectedDateKey) ? _selectedDateKey : 'ALL',
          icon: const Icon(Icons.calendar_today_rounded, size: 16),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
          dropdownColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
          items: dateOptions.map((d) {
            String label = 'All Past Dates';
            if (d != 'ALL') {
              try {
                final parsed = DateTime.parse(d);
                label = DateFormat('MMM dd, yyyy').format(parsed);
              } catch (_) {
                label = d;
              }
            }
            return DropdownMenuItem<String>(
              value: d,
              child: Text(label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDateKey = val);
              _loadArchiveData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String currentValue,
    ValueChanged<String> onSelected,
    bool isDark, {
    Color? color,
  }) {
    final isSelected = value == currentValue;
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceLight : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, bool isDark, bool isCompact) {
    final filtered = _filteredEntries;
    final total = filtered.length;
    final completed = filtered.where((e) => e.isCompleted).length;
    final skipped = filtered.where((e) => e.isSkipped).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceMid.withValues(alpha: 0.6)
            : AppColors.lightSurfaceMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Records', '$total', AppColors.primary, isDark),
          _buildStatItem('Completed', '$completed', AppColors.success, isDark),
          _buildStatItem('Skipped', '$skipped', AppColors.warning, isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildArchiveList(BuildContext context, bool isDark, bool isCompact) {
    final filtered = _filteredEntries;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'No Archived Patients Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Past queue entries with dates and purposes will be archived here each day',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _buildArchiveCard(context, entry, isDark, isCompact);
      },
    );
  }

  Widget _buildArchiveCard(
    BuildContext context,
    QueueEntry entry,
    bool isDark,
    bool isCompact,
  ) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final isEnt = entry.department == 'ENT';
    final deptColor = isEnt ? AppColors.entColor : AppColors.eyesColor;

    Color statusColor = AppColors.primary;
    String statusText = 'Completed';
    if (entry.status == 'skipped') {
      statusColor = AppColors.warning;
      statusText = 'Skipped';
    } else if (entry.status == 'on_hold') {
      statusColor = AppColors.onHold;
      statusText = 'On Hold';
    } else if (entry.status == 'serving') {
      statusColor = AppColors.nowServing;
      statusText = 'Served';
    }

    // Format created date & time
    final dateStr = DateFormat('MMM dd, yyyy').format(entry.createdAt);
    final timeStr = DateFormat('hh:mm a').format(entry.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date, Ticket, Department, Status
          Row(
            children: [
              // Ticket Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deptColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: deptColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  entry.queueNumber,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: deptColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Department Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : AppColors.lightBg),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.department,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: deptColor,
                  ),
                ),
              ),
              const Spacer(),
              // Date & Time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: subtitleColor),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• $timeStr',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Middle Row: Patient Name & ID
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.patientName,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (entry.patientId.isNotEmpty)
                      Text(
                        'Patient ID: ${entry.patientId}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom Row: Purpose, Doctor, Room
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : AppColors.lightBg)
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // PURPOSE (Prominently Highlighted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Purpose: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.purpose,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),

                // DOCTOR
                if (entry.assignedDoctor != null &&
                    entry.assignedDoctor!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_pin_rounded,
                          size: 15, color: subtitleColor),
                      const SizedBox(width: 4),
                      Text(
                        'Doctor: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                      Text(
                        entry.assignedDoctor!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),

                // ROOM
                if (entry.assignedRoom != null && entry.assignedRoom!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.meeting_room_rounded,
                          size: 15, color: subtitleColor),
                      const SizedBox(width: 4),
                      Text(
                        'Room: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                      Text(
                        entry.assignedRoom!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
