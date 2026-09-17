import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/clinic_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  // Doctor role emerald palette (replaces blue)
  static const Color emeraldPrimary = Color(0xFF059669);
  static const Color emeraldDark = Color(0xFF047857);

  /// Helper to format clean doctor name without duplicate "Dr. DR." and proper casing
  String _formatDoctorDisplayName(String rawName) {
    return DoctorProvider.formatDoctorName(rawName);
  }

  /// Get image provider from URL, base64 data URI, or local file
  ImageProvider _getDoctorImageProvider(String path) {
    if (path.startsWith('data:image')) {
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      return FileImage(File(path));
    }
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final clinicProv = context.watch<ClinicProvider>();

    final completedCount = doctorProv.getCompletedPatients(queueProv.todayQueue).length;
    final waitingCount = doctorProv.getAllWaitingPatients(queueProv.todayQueue).length;
    final totalPatients = doctorProv.patients.length;
    final hasPhoto = doctorProv.photoUrl != null && doctorProv.photoUrl!.isNotEmpty;

    // Format schedule text dynamically from doctorProv.schedule
    final schedule = doctorProv.schedule;
    final mon = schedule.days['monday'];
    final scheduleSummary = (mon != null && mon.isAvailable)
        ? 'Mon - Fri • ${mon.startTime} - ${mon.endTime}'
        : 'Regular Clinic Hours';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, size: 22, color: emeraldPrimary),
            SizedBox(width: 8),
            Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Doctor',
            icon: const Icon(Icons.switch_account_rounded),
            onPressed: () => _showDoctorSwitcher(context, doctorProv, clinicProv),
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _showEditProfileDialog(context, doctorProv, clinicProv),
          ),
          const SizedBox(width: 8),
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
                // ── Hero Banner Card (Emerald theme, no blue) ───────
                Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      // Header Emerald Gradient Banner
                      Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF047857), // Deep emerald
                              Color(0xFF059669), // Rich emerald
                              Color(0xFF022C22), // Dark emerald slate
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 20,
                              top: 20,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      'ACTIVE ON DUTY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Avatar & Details overlap
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -48),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Avatar with live photo support
                                  GestureDetector(
                                    onTap: () => _showEditProfileDialog(context, doctorProv, clinicProv),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context).cardColor,
                                              width: 4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.18),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 44,
                                            backgroundColor: emeraldPrimary,
                                            backgroundImage: hasPhoto
                                                ? _getDoctorImageProvider(doctorProv.photoUrl!)
                                                : null,
                                            child: hasPhoto
                                                ? null
                                                : Text(
                                                    doctorProv.activeDoctor.isNotEmpty
                                                        ? doctorProv.activeDoctor
                                                            .replaceAll('Dr. ', '')
                                                            .replaceAll('DR. ', '')
                                                            .replaceAll('Engr. ', '')
                                                            .trim()[0]
                                                            .toUpperCase()
                                                        : 'D',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 36,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        // Edit Photo badge
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: emeraldDark,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.photo_camera_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 42),
                                        Text(
                                          _formatDoctorDisplayName(doctorProv.activeDoctor),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: emeraldPrimary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${doctorProv.activeDepartment} Specialist',
                                                style: const TextStyle(
                                                  color: emeraldDark,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '•  ${doctorProv.activeRoom}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _showEditProfileDialog(context, doctorProv, clinicProv),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit Profile'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: emeraldPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -18),
                              child: Center(
                                child: Text(
                                  doctorProv.bio.isNotEmpty
                                      ? doctorProv.bio
                                      : 'Specialist in clinical diagnosis, surgery, and outpatient care.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Real Dynamic Stats Grid (No Static Data) ────────
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.history_edu_rounded,
                        label: 'Experience',
                        value: '${doctorProv.yearsOfExperience} yrs',
                        subtext: 'Clinical practice',
                        color: emeraldPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.people_alt_rounded,
                        label: 'Registered Patients',
                        value: '$totalPatients',
                        subtext: 'Reception uploaded',
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.task_alt_rounded,
                        label: 'Completed Today',
                        value: '$completedCount',
                        subtext: 'Patients consulted',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Waiting in Line',
                        value: '$waitingCount',
                        subtext: 'Current queue',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Professional & Contact Information ───────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professional Info Card
                    Expanded(
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.medical_services_rounded, color: emeraldPrimary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Professional Information',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.domain_rounded,
                                label: 'Department',
                                value: doctorProv.activeDepartment,
                              ),
                              _buildInfoRow(
                                icon: Icons.meeting_room_rounded,
                                label: 'Assigned Consultation Room',
                                value: doctorProv.activeRoom,
                              ),
                              _buildInfoRow(
                                icon: Icons.card_membership_rounded,
                                label: 'License / PRC Number',
                                value: doctorProv.licenseNumber.isNotEmpty ? doctorProv.licenseNumber : 'Not set',
                              ),
                              _buildInfoRow(
                                icon: Icons.schedule_rounded,
                                label: 'Working Schedule',
                                value: scheduleSummary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Contact & Credentials Card
                    Expanded(
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.contact_phone_rounded, color: emeraldPrimary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Contact & Clinic Details',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.email_rounded,
                                label: 'Email Address',
                                value: doctorProv.doctorEmail.isNotEmpty ? doctorProv.doctorEmail : 'Not set',
                              ),
                              _buildInfoRow(
                                icon: Icons.phone_rounded,
                                label: 'Clinic Contact Number',
                                value: doctorProv.doctorPhone.isNotEmpty ? doctorProv.doctorPhone : 'Not set',
                              ),
                              _buildInfoRow(
                                icon: Icons.location_on_rounded,
                                label: 'Clinic Location',
                                value: 'Our Lady of Fatima Eye, Ear, Nose & Throat Center',
                              ),
                              _buildInfoRow(
                                icon: Icons.verified_user_rounded,
                                label: 'Verification Status',
                                value: 'Verified Doctor • Board Certified',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              subtext,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog to dynamically select active doctor from ClinicProvider / Supabase
  void _showDoctorSwitcher(
    BuildContext context,
    DoctorProvider doctorProv,
    ClinicProvider clinicProv,
  ) {
    final docs = clinicProv.doctors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.switch_account_rounded, color: emeraldPrimary),
            SizedBox(width: 8),
            Text('Select Active Doctor Profile'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: docs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No doctors configured in clinic database.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final isSelected = doctorProv.activeDoctor == d.name;
                    const color = emeraldPrimary;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      tileColor: isSelected ? color.withValues(alpha: 0.08) : null,
                      leading: CircleAvatar(
                        backgroundColor: color,
                        backgroundImage: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                            ? _getDoctorImageProvider(d.photoUrl!)
                            : null,
                        child: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                            ? null
                            : Text(
                                d.name.isNotEmpty ? d.name.substring(0, 1) : 'D',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      title: Text(_formatDoctorDisplayName(d.name),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${d.department} • ${d.room ?? 'Room 1'}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: color)
                          : null,
                      onTap: () {
                        doctorProv.selectDoctorModel(d);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${_formatDoctorDisplayName(d.name)}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: color,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Dialog to edit doctor profile with Photo Upload working
  void _showEditProfileDialog(
    BuildContext context,
    DoctorProvider doctorProv,
    ClinicProvider clinicProv,
  ) {
    final nameCtrl = TextEditingController(text: doctorProv.activeDoctor);
    final roomCtrl = TextEditingController(text: doctorProv.activeRoom);
    final emailCtrl = TextEditingController(text: doctorProv.doctorEmail);
    final phoneCtrl = TextEditingController(text: doctorProv.doctorPhone);
    final licenseCtrl = TextEditingController(text: doctorProv.licenseNumber);
    final expCtrl = TextEditingController(text: doctorProv.yearsOfExperience > 0 ? doctorProv.yearsOfExperience.toString() : '');
    final bioCtrl = TextEditingController(text: doctorProv.bio);
    final urlCtrl = TextEditingController();
    String selectedDept = doctorProv.activeDepartment;
    String? currentPhoto = doctorProv.photoUrl;
    bool showUrlInput = false;

    // 6 Curated High-Resolution Medical Doctor Avatars
    final presetAvatars = [
      {
        'label': 'Male Doctor 1',
        'url': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=300&q=80',
      },
      {
        'label': 'Female Doctor 1',
        'url': 'https://images.unsplash.com/photo-1594824813512-25916d7a4697?w=300&q=80',
      },
      {
        'label': 'Male Doctor 2',
        'url': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=300&q=80',
      },
      {
        'label': 'Female Doctor 2',
        'url': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300&q=80',
      },
      {
        'label': 'Specialist 1',
        'url': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=300&q=80',
      },
      {
        'label': 'Specialist 2',
        'url': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=300&q=80',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickLocalImage() async {
            try {
              final picker = ImagePicker();
              final xfile = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 600,
                imageQuality: 85,
              );
              if (xfile != null) {
                final bytes = await xfile.readAsBytes();
                final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';
                setDialogState(() {
                  currentPhoto = dataUri;
                });
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File picker notice: $e. You can also pick a preset avatar or paste an image URL.'),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                );
              }
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_rounded, color: emeraldPrimary),
                SizedBox(width: 8),
                Text('Edit Doctor Profile'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Photo Avatar & Controls ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: emeraldPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: emeraldPrimary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: emeraldPrimary,
                                backgroundImage: (currentPhoto != null && currentPhoto!.isNotEmpty)
                                    ? _getDoctorImageProvider(currentPhoto!)
                                    : null,
                                child: (currentPhoto != null && currentPhoto!.isNotEmpty)
                                    ? null
                                    : const Icon(Icons.person, size: 52, color: Colors.white),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: pickLocalImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: emeraldDark,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: pickLocalImage,
                                icon: const Icon(Icons.upload_file_rounded, size: 16),
                                label: const Text('Upload Photo', style: TextStyle(fontSize: 12)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: emeraldPrimary.withValues(alpha: 0.15),
                                  foregroundColor: emeraldDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    showUrlInput = !showUrlInput;
                                  });
                                },
                                icon: const Icon(Icons.link_rounded, size: 16),
                                label: const Text('Image URL', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              if (currentPhoto != null && currentPhoto!.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      currentPhoto = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  label: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                ),
                            ],
                          ),

                          // Quick URL Input Field if toggled
                          if (showUrlInput) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: urlCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'https://... or local file path',
                                      labelText: 'Direct Photo URL / Path',
                                      isDense: true,
                                      prefixIcon: Icon(Icons.image_search_rounded, size: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: emeraldPrimary),
                                  onPressed: () {
                                    final val = urlCtrl.text.trim();
                                    if (val.isNotEmpty) {
                                      setDialogState(() {
                                        currentPhoto = val;
                                        showUrlInput = false;
                                      });
                                    }
                                  },
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quick Presets (Select Doctor Avatar):',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: presetAvatars.map((preset) {
                                final pUrl = preset['url']!;
                                final isSelected = currentPhoto == pUrl;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      setDialogState(() {
                                        currentPhoto = pUrl;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? emeraldPrimary : Colors.grey.withValues(alpha: 0.3),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: NetworkImage(pUrl),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.domain),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ENT', child: Text('ENT (Ear, Nose, Throat)')),
                        DropdownMenuItem(value: 'EYES', child: Text('EYES (Ophthalmology)')),
                        DropdownMenuItem(value: 'BOTH', child: Text('BOTH Departments')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDept = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: roomCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Room',
                              prefixIcon: Icon(Icons.meeting_room),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: expCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Years Experience',
                              prefixIcon: Icon(Icons.work),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: licenseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License / PRC #',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Bio / Professional Summary',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: emeraldPrimary),
                onPressed: () {
                  final formattedName = DoctorProvider.formatDoctorName(nameCtrl.text.trim());
                  final exp = int.tryParse(expCtrl.text.trim()) ?? doctorProv.yearsOfExperience;

                  doctorProv.updateProfile(
                    name: formattedName,
                    department: selectedDept,
                    room: roomCtrl.text.trim(),
                    photoUrl: currentPhoto,
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    license: licenseCtrl.text.trim(),
                    experience: exp,
                    doctorBio: bioCtrl.text.trim(),
                  );

                  // Synchronize with ClinicProvider & Supabase
                  clinicProv.updateDoctor(doctorProv.toDoctorModel());

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile for $formattedName and photo updated successfully'),
                      backgroundColor: emeraldPrimary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
