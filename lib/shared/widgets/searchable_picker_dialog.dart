import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PickerItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final String department; // 'ENT', 'EYES', 'BOTH'
  final IconData icon;

  const PickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.department = 'BOTH',
    this.icon = Icons.circle_outlined,
  });
}

/// A modal dialog that allows searching, filtering by department,
/// and selecting an item (Doctor, Room, etc.).
Future<T?> showSearchablePicker<T>(
  BuildContext context, {
  required String title,
  required String searchHint,
  required List<PickerItem<T>> items,
  T? selectedValue,
  bool isDark = false,
  VoidCallback? onAddNew,
  String addNewLabel = 'Add New',
}) async {
  return showDialog<T>(
    context: context,
    builder: (ctx) => _SearchablePickerDialog<T>(
      title: title,
      searchHint: searchHint,
      items: items,
      selectedValue: selectedValue,
      isDark: isDark,
      onAddNew: onAddNew,
      addNewLabel: addNewLabel,
    ),
  );
}

class _SearchablePickerDialog<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<PickerItem<T>> items;
  final T? selectedValue;
  final bool isDark;
  final VoidCallback? onAddNew;
  final String addNewLabel;

  const _SearchablePickerDialog({
    required this.title,
    required this.searchHint,
    required this.items,
    this.selectedValue,
    required this.isDark,
    this.onAddNew,
    required this.addNewLabel,
  });

  @override
  State<_SearchablePickerDialog<T>> createState() =>
      _SearchablePickerDialogState<T>();
}

class _SearchablePickerDialogState<T> extends State<_SearchablePickerDialog<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedDeptFilter = 'ALL'; // 'ALL', 'ENT', 'EYES'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PickerItem<T>> _getFilteredItems() {
    final query = _searchCtrl.text.trim().toLowerCase();
    return widget.items.where((item) {
      // Department filter
      if (_selectedDeptFilter != 'ALL') {
        final itemDept = item.department.toUpperCase();
        if (itemDept != 'BOTH' && itemDept != _selectedDeptFilter) {
          return false;
        }
      }

      // Query filter
      if (query.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchSub = item.subtitle?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchSub) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final filtered = _getFilteredItems();

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (widget.onAddNew != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Defer onAddNew until after the dialog is fully disposed
                        // to avoid the '_dependents.isEmpty' assertion error.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.onAddNew!();
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(widget.addNewLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: subtitleColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style:
                    TextStyle(color: titleColor, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textDisabled
                        : AppColors.lightTextDisabled,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceLight.withValues(alpha: 0.4)
                      : AppColors.lightBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Department Filters Chips: [ All | ENT | EYES ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    'FILTER:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('ALL', 'All'),
                  const SizedBox(width: 6),
                  _buildFilterChip('ENT', 'ENT'),
                  const SizedBox(width: 6),
                  _buildFilterChip('EYES', 'Eyes'),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1),

            // Items List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: subtitleColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No matching items found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                            if (widget.onAddNew != null) ...[
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Defer onAddNew until after the dialog is fully disposed
                                  // to avoid the '_dependents.isEmpty' assertion error.
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    widget.onAddNew!();
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(widget.addNewLabel),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = widget.selectedValue == item.value;
                        return _buildItemCard(item, isSelected);
                      },
                    ),
            ),

            // Bottom Clear Selection Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: subtitleColor,
                    ),
                    child: const Text('Clear / Unassigned'),
                  ),
                  Text(
                    '${filtered.length} available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String deptKey, String label) {
    final isSelected = _selectedDeptFilter == deptKey;
    final isDark = widget.isDark;

    Color activeColor;
    if (deptKey == 'ENT') {
      activeColor = AppColors.entColor;
    } else if (deptKey == 'EYES') {
      activeColor = AppColors.eyesColor;
    } else {
      activeColor = AppColors.primary;
    }

    return InkWell(
      onTap: () => setState(() => _selectedDeptFilter = deptKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppColors.surfaceLight : AppColors.lightBg),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.surfaceLight : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(PickerItem<T> item, bool isSelected) {
    final isDark = widget.isDark;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    Color deptColor;
    if (item.department.toUpperCase() == 'ENT') {
      deptColor = AppColors.entColor;
    } else if (item.department.toUpperCase() == 'EYES') {
      deptColor = AppColors.eyesColor;
    } else {
      deptColor = AppColors.cyanCalm;
    }

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
          : (isDark ? AppColors.surfaceLight.withValues(alpha: 0.35) : AppColors.lightBg),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item.value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.surfaceLight : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: deptColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: deptColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: deptColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: deptColor.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            item.department.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: deptColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
