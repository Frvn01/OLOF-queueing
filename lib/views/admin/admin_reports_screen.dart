import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/queue_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _departmentFilter = 'ALL';
  String _statusFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final queueProv = context.watch<QueueProvider>();
    final todayQueue = queueProv.todayQueue;

    final filtered = todayQueue.where((e) {
      if (_departmentFilter != 'ALL' && e.department != _departmentFilter) return false;
      if (_statusFilter != 'ALL' && e.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return e.patientName.toLowerCase().contains(q) ||
            e.queueNumber.toLowerCase().contains(q) ||
            e.purpose.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats summary
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Clinical Visit Logs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Comprehensive log of patients, assigned doctors, and consultation timestamps.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // Archive link
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/archive'),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Past Dates Archive'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Filters Row
          Row(
            children: [
              SizedBox(
                width: 260,
                height: 38,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search log entries...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              const SizedBox(width: 14),
              DropdownButton<String>(
                value: _departmentFilter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                  DropdownMenuItem(value: AppConstants.deptEnt, child: Text('ENT')),
                  DropdownMenuItem(value: AppConstants.deptEyes, child: Text('EYES')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _departmentFilter = val);
                },
              ),
              const SizedBox(width: 14),
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                  DropdownMenuItem(value: AppConstants.statusCompleted, child: Text('Completed')),
                  DropdownMenuItem(value: AppConstants.statusServing, child: Text('Serving')),
                  DropdownMenuItem(value: AppConstants.statusWaiting, child: Text('Waiting')),
                  DropdownMenuItem(value: AppConstants.statusSkipped, child: Text('Skipped')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _statusFilter = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
              ),
              child: filtered.isEmpty
                  ? const Center(child: Text('No log entries match your filter criteria.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Ticket #')),
                            DataColumn(label: Text('Patient Name')),
                            DataColumn(label: Text('Department')),
                            DataColumn(label: Text('Purpose')),
                            DataColumn(label: Text('Assigned Doctor')),
                            DataColumn(label: Text('Room')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Called At')),
                            DataColumn(label: Text('Completed At')),
                          ],
                          rows: filtered.map((e) {
                            return DataRow(
                              cells: [
                                DataCell(Text(e.queueNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(e.patientName)),
                                DataCell(Text(e.department)),
                                DataCell(Text(e.purpose)),
                                DataCell(Text(e.assignedDoctor ?? 'Unassigned')),
                                DataCell(Text(e.assignedRoom ?? '-')),
                                DataCell(_buildStatusBadge(e.status)),
                                DataCell(Text(e.calledAt != null
                                    ? '${e.calledAt!.hour}:${e.calledAt!.minute.toString().padLeft(2, '0')}'
                                    : '-')),
                                DataCell(Text(e.completedAt != null
                                    ? '${e.completedAt!.hour}:${e.completedAt!.minute.toString().padLeft(2, '0')}'
                                    : '-')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.success;
        break;
      case 'serving':
        color = AppColors.primary;
        break;
      case 'waiting':
        color = const Color(0xFFF59E0B);
        break;
      case 'skipped':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
