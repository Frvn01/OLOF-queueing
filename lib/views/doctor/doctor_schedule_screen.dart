import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/doctor_schedule.dart';
import '../../providers/doctor_provider.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  late DoctorSchedule _localSchedule;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final doctorProv = context.read<DoctorProvider>();
      _localSchedule = doctorProv.schedule;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    const themeColor = AppColors.doctorPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              'My Schedule • ${doctorProv.formattedDoctorName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _applyWeekdayTemplate,
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('Sync Weekdays'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _saveSchedule(context, doctorProv),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Schedule'),
            style: FilledButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Schedule Header Banner ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.access_time_rounded, color: themeColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Availability & Time Slots',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set consultation hours, break periods, and slot durations for each day. Changes take effect on the kiosk queue.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reset to Defaults',
                        icon: const Icon(Icons.restart_alt_rounded),
                        onPressed: () {
                          setState(() {
                            _localSchedule = DoctorSchedule.defaultSchedule(
                              doctorId: doctorProv.activeDoctor,
                              doctorName: doctorProv.activeDoctor,
                              room: doctorProv.activeRoom,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reset to default clinic schedule')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Day Schedule Cards List ─────────────────────────
                ...DoctorSchedule.dayKeys.map((dayKey) {
                  final daySchedule = _localSchedule.days[dayKey] ?? DaySchedule();
                  final dayLabel = DoctorSchedule.dayLabels[dayKey] ?? dayKey;
                  final isWeekend = dayKey == 'saturday' || dayKey == 'sunday';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: daySchedule.isAvailable ? 1 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: daySchedule.isAvailable
                            ? themeColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: daySchedule.isAvailable ? 1.5 : 1,
                      ),
                    ),
                    color: daySchedule.isAvailable
                        ? Theme.of(context).cardColor
                        : Theme.of(context).cardColor.withValues(alpha: 0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Header Row
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: daySchedule.isAvailable ? AppColors.success : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: daySchedule.isAvailable ? null : Colors.grey,
                                ),
                              ),
                              if (isWeekend) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'WEEKEND',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                daySchedule.isAvailable ? 'Available' : 'Day Off',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: daySchedule.isAvailable ? AppColors.success : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: daySchedule.isAvailable,
                                activeThumbColor: themeColor,
                                onChanged: (val) {
                                  setState(() {
                                    final updatedDays = Map<String, DaySchedule>.from(_localSchedule.days);
                                    updatedDays[dayKey] = daySchedule.copyWith(isAvailable: val);
                                    _localSchedule = DoctorSchedule(
                                      doctorId: _localSchedule.doctorId,
                                      doctorName: _localSchedule.doctorName,
                                      days: updatedDays,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),

                          if (daySchedule.isAvailable) ...[
                            const Divider(height: 20),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Start Time
                                _buildTimeSlotSelector(
                                  context: context,
                                  label: 'Start Time',
                                  icon: Icons.login_rounded,
                                  timeString: daySchedule.startTime,
                                  onChanged: (newTime) {
                                    _updateDay(dayKey, daySchedule.copyWith(startTime: newTime));
                                  },
                                ),
                                // End Time
                                _buildTimeSlotSelector(
                                  context: context,
                                  label: 'End Time',
                                  icon: Icons.logout_rounded,
                                  timeString: daySchedule.endTime,
                                  onChanged: (newTime) {
                                    _updateDay(dayKey, daySchedule.copyWith(endTime: newTime));
                                  },
                                ),
                                // Break Start
                                _buildTimeSlotSelector(
                                  context: context,
                                  label: 'Break Start',
                                  icon: Icons.coffee_rounded,
                                  timeString: daySchedule.breakStart.isNotEmpty ? daySchedule.breakStart : 'None',
                                  onChanged: (newTime) {
                                    _updateDay(dayKey, daySchedule.copyWith(breakStart: newTime));
                                  },
                                ),
                                // Break End
                                _buildTimeSlotSelector(
                                  context: context,
                                  label: 'Break End',
                                  icon: Icons.work_history_rounded,
                                  timeString: daySchedule.breakEnd.isNotEmpty ? daySchedule.breakEnd : 'None',
                                  onChanged: (newTime) {
                                    _updateDay(dayKey, daySchedule.copyWith(breakEnd: newTime));
                                  },
                                ),
                                // Slot Duration
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timelapse_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      const Text('Slot: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      DropdownButton<int>(
                                        value: daySchedule.slotDurationMinutes,
                                        isDense: true,
                                        underline: const SizedBox.shrink(),
                                        items: const [
                                          DropdownMenuItem(value: 15, child: Text('15 min')),
                                          DropdownMenuItem(value: 20, child: Text('20 min')),
                                          DropdownMenuItem(value: 30, child: Text('30 min')),
                                          DropdownMenuItem(value: 45, child: Text('45 min')),
                                          DropdownMenuItem(value: 60, child: Text('60 min')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            _updateDay(dayKey, daySchedule.copyWith(slotDurationMinutes: val));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Max patients per slot
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      const Text('Max: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      DropdownButton<int>(
                                        value: daySchedule.maxPatientsPerSlot,
                                        isDense: true,
                                        underline: const SizedBox.shrink(),
                                        items: const [
                                          DropdownMenuItem(value: 1, child: Text('1 / slot')),
                                          DropdownMenuItem(value: 2, child: Text('2 / slot')),
                                          DropdownMenuItem(value: 3, child: Text('3 / slot')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            _updateDay(dayKey, daySchedule.copyWith(maxPatientsPerSlot: val));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String timeString,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
        if (timeString.contains(':')) {
          final parts = timeString.split(':');
          initial = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final formatted =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(timeString, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateDay(String dayKey, DaySchedule updated) {
    setState(() {
      final updatedDays = Map<String, DaySchedule>.from(_localSchedule.days);
      updatedDays[dayKey] = updated;
      _localSchedule = DoctorSchedule(
        doctorId: _localSchedule.doctorId,
        doctorName: _localSchedule.doctorName,
        days: updatedDays,
      );
    });
  }

  void _applyWeekdayTemplate() {
    final monday = _localSchedule.days['monday'] ?? DaySchedule();
    setState(() {
      final updatedDays = Map<String, DaySchedule>.from(_localSchedule.days);
      for (final key in ['tuesday', 'wednesday', 'thursday', 'friday']) {
        updatedDays[key] = monday.copyWith();
      }
      _localSchedule = DoctorSchedule(
        doctorId: _localSchedule.doctorId,
        doctorName: _localSchedule.doctorName,
        days: updatedDays,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monday settings synced across Tuesday–Friday')),
    );
  }

  void _saveSchedule(BuildContext context, DoctorProvider doctorProv) {
    doctorProv.saveSchedule(_localSchedule);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Doctor Weekly Schedule Saved Successfully'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
