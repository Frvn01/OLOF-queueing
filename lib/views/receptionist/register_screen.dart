import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/patient_provider.dart';
import '../../data/models/patient.dart';
import '../../data/models/patient_dept_record.dart';
import '../../data/repositories/patient_dept_repository.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/pmh_medication_dialog.dart';
import '../../shared/widgets/queue_ticket_print.dart';
import '../../providers/theme_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../data/models/doctor.dart';
import '../../data/models/clinic_room.dart';
import '../../shared/widgets/photo_source_dialog.dart';
import '../../shared/widgets/searchable_picker_dialog.dart';
import '../../data/models/visit_record.dart';
import '../../core/utils/helpers.dart';
import '../../providers/queue_provider.dart';

/// New patient registration form — Responsive multi-step wizard
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  int _currentStep = 0; // 0=Dept, 1=Personal, 2=Contact, 3=Clinical

  // ── Step 0: Department selection ──────────────────────────────────
  String _selectedConsultationType = 'ENT'; // 'ENT', 'EYES', 'BOTH'

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _occupationController = TextEditingController();
  final _referredByController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _historyIllnessController = TextEditingController();
  final _pastMedicalController = TextEditingController();

  DateTime? _birthday;
  String _sex = 'Male';
  String _civilStatus = 'Single';
  bool _isSubmitting = false;
  Patient? _registeredPatient;
  // Issued queue tickets after successful registration
  final List<QueueTicketData> _issuedTickets = [];

  // Photo picker state
  Uint8List? _photoBytes;
  String _photoFileName = 'photo.jpg';
  final ImagePicker _picker = ImagePicker();

  // Doctor & Room selection state
  bool _isFirstTime = true;
  Doctor? _selectedDoctor;
  ClinicRoom? _selectedRoom;
  bool _didAutoAssignInitialRoom = false;
  bool _roomExplicitlyCleared = false;

  // Past Medical History checkboxes
  bool _pmhHypertension = false;
  bool _pmhDM = false;
  bool _pmhAllergies = false;
  bool _pmhOperations = false;
  bool _pmhMedications = false;
  bool _pmhGlaucoma = false;
  final _pmhOtherController = TextEditingController();

  // Structured medications per condition (populated by medication dialog)
  final Map<String, List<String>> _pmhConditionMeds = {};

  // Dept record repository
  final _deptRepo = PatientDeptRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoAssignInitialRoom) {
      _didAutoAssignInitialRoom = true;
      if (_selectedConsultationType != 'BOTH') {
        final clinic = context.read<ClinicProvider>();
        final matchingRooms = clinic.getRooms(department: _selectedConsultationType);
        if (matchingRooms.isNotEmpty) {
          _selectedRoom = matchingRooms.first;
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _occupationController.dispose();
    _referredByController.dispose();
    _chiefComplaintController.dispose();
    _historyIllnessController.dispose();
    _pastMedicalController.dispose();
    _pmhOtherController.dispose();
    super.dispose();
  }

  // ── Step 0: Department selection widget ──────────────────────────
  Widget _buildDepartmentStep(bool isDark, bool isCompact, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.30) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceHover : AppColors.lightBorder;

    Widget deptCard({
      required String dept,
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
    }) {
      final isSelected = _selectedConsultationType == dept;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final clinic = context.read<ClinicProvider>();
            setState(() {
              _selectedConsultationType = dept;
              _selectedDoctor = null;
              _roomExplicitlyCleared = false;
              if (dept == 'BOTH') {
                _selectedRoom = null;
              } else {
                final matchingRooms = clinic.getRooms(department: dept);
                _selectedRoom = matchingRooms.isNotEmpty ? matchingRooms.first : null;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.22 : 0.10)
                  : cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.22 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: isCompact ? 24 : 28),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? color : titleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Selected ✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dept cards
        if (isLandscape)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              deptCard(
                dept: 'ENT',
                label: 'ENT Clinic',
                subtitle: 'Ear, Nose & Throat',
                icon: Icons.hearing_rounded,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 10),
              deptCard(
                dept: 'EYES',
                label: 'EYES Clinic',
                subtitle: 'Ophthalmology',
                icon: Icons.visibility_rounded,
                color: AppColors.cyanCalm,
              ),
              const SizedBox(width: 10),
              deptCard(
                dept: 'BOTH',
                label: 'Both Clinics',
                subtitle: 'ENT + EYES',
                icon: Icons.sync_alt_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              deptCard(
                dept: 'ENT',
                label: 'ENT',
                subtitle: 'Ear, Nose\n& Throat',
                icon: Icons.hearing_rounded,
                color: AppColors.brandBlue,
              ),
              const SizedBox(width: 10),
              deptCard(
                dept: 'EYES',
                label: 'EYES',
                subtitle: 'Ophthal-\nomology',
                icon: Icons.visibility_rounded,
                color: AppColors.cyanCalm,
              ),
              const SizedBox(width: 10),
              deptCard(
                dept: 'BOTH',
                label: 'BOTH',
                subtitle: 'ENT +\nEYES',
                icon: Icons.sync_alt_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),

        SizedBox(height: isLandscape ? 14 : 20),

        // Ticket info banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (_selectedConsultationType == 'ENT'
                    ? AppColors.brandBlue
                    : _selectedConsultationType == 'EYES'
                        ? AppColors.cyanCalm
                        : const Color(0xFF8B5CF6))
                .withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_selectedConsultationType == 'ENT'
                      ? AppColors.brandBlue
                      : _selectedConsultationType == 'EYES'
                          ? AppColors.cyanCalm
                          : const Color(0xFF8B5CF6))
                  .withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_rounded,
                size: 16,
                color: _selectedConsultationType == 'ENT'
                    ? AppColors.brandBlue
                    : _selectedConsultationType == 'EYES'
                        ? AppColors.cyanCalm
                        : const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedConsultationType == 'BOTH'
                      ? 'Two queue tickets will be issued: one for ENT and one for EYES.'
                      : 'One queue ticket will be issued for the $_selectedConsultationType clinic upon registration.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isLandscape ? 14 : 20),

        // Returning patient lookup shortcut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Returning Patient?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'Look up existing profile to add a new consultation without re-entering demographics.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/receptionist'),
                child: const Text(
                  'Look Up Profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDarkest : AppColors.lightBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.surfaceGradient
              : AppColors.lightSurfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: _registeredPatient != null
                    ? _buildSuccessView(context, isDark, isLandscape)
                    : _buildWizard(context, isDark, isLandscape),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/receptionist'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Back to Receptionist Station',
          ),
          const SizedBox(width: 4),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _registeredPatient != null
                  ? 'Registration Complete'
                  : 'New Patient Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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

  Widget _buildWizard(BuildContext context, bool isDark, bool isLandscape) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500 && !isLandscape;
    // In landscape: use less padding and spacing to fit everything on screen
    final hPad = isLandscape ? 12.0 : (isCompact ? 16.0 : 24.0);
    final vPad = isLandscape ? 8.0 : (isCompact ? 16.0 : 24.0);
    final cardPad = isLandscape ? 14.0 : (isCompact ? 18.0 : 26.0);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Progress Bar
              _buildStepIndicator(isDark, isCompact),
              SizedBox(height: isLandscape ? 10 : 20),

              // Main Form Card
              Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Title & Subtitle
                    _buildStepHeader(isDark, isLandscape),
                    SizedBox(height: isLandscape ? 12 : 22),

                    // Step Form Content
                    if (_currentStep == 0)
                      _buildDepartmentStep(isDark, isCompact, isLandscape)
                    else if (_currentStep == 1)
                      Form(
                        key: _formKey1,
                        child: _buildPersonalInfoStep(isDark, isCompact, isLandscape),
                      )
                    else if (_currentStep == 2)
                      Form(
                        key: _formKey2,
                        child: _buildContactStep(isDark, isCompact, isLandscape),
                      )
                    else
                      Form(
                        key: _formKey3,
                        child: _buildMedicalStep(isDark, isCompact, isLandscape),
                      ),

                    SizedBox(height: isLandscape ? 16 : 32),

                    // Navigation Buttons
                    _buildStepButtons(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark, bool isCompact) {
    final steps = [
      {'num': '1', 'title': 'Dept'},
      {'num': '2', 'title': 'Personal'},
      {'num': '3', 'title': 'Contact'},
      {'num': '4', 'title': 'Clinical'},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIdx = index ~/ 2;
          final isCompleted = _currentStep > stepIdx;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceLight : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final isActive = _currentStep == stepIdx;
        final isCompleted = _currentStep > stepIdx;
        final step = steps[stepIdx];

        Color circleBg;
        Color textColor;
        Color borderColor;

        if (isActive) {
          circleBg = AppColors.primary;
          textColor = Colors.white;
          borderColor = AppColors.primary;
        } else if (isCompleted) {
          circleBg = AppColors.success;
          textColor = Colors.white;
          borderColor = AppColors.success;
        } else {
          circleBg = isDark ? AppColors.surfaceMid : AppColors.lightSurfaceMid;
          textColor = isDark ? AppColors.textDisabled : AppColors.lightTextDisabled;
          borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
        }

        return InkWell(
          onTap: isCompleted ? () => setState(() => _currentStep = stepIdx) : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                        : Text(
                            step['num']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  Text(
                    step['title']!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepHeader(bool isDark, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    String title;
    String subtitle;
    IconData icon;

    switch (_currentStep) {
      case 0:
        title = 'Consultation Department';
        subtitle = 'Select ENT, EYES, or both — a queue ticket will be issued';
        icon = Icons.local_hospital_rounded;
        break;
      case 1:
        title = 'Personal Information';
        subtitle = 'Legal full name, date of birth, biological sex & status';
        icon = Icons.badge_rounded;
        break;
      case 2:
        title = 'Contact & Residence';
        subtitle = 'Mobile contact number, complete address & referral';
        icon = Icons.contact_phone_rounded;
        break;
      default:
        title = 'Initial Clinical Intake';
        subtitle = 'Chief complaint, history of illness & past medical notes';
        icon = Icons.medical_information_rounded;
        break;
    }

    if (isLandscape) {
      // Compact inline header for landscape
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep(bool isDark, bool isCompact, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    // Use side-by-side rows in landscape OR on wide screens
    final useRows = !isCompact || isLandscape;
    final gap = isLandscape ? 12.0 : 16.0;

    return Column(
      children: [
        // ── Photo Picker ──────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: isLandscape ? 80 : 100,
                      height: isLandscape ? 80 : 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        image: _photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_photoBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _photoBytes == null
                          ? Icon(
                              Icons.person_rounded,
                              size: isLandscape ? 38 : 48,
                              color: subtitleColor,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (!isLandscape) const SizedBox(height: 6),
              if (!isLandscape)
                Text(
                  _photoBytes != null ? 'Tap to change photo' : 'Tap to add photo (optional)',
                  style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
        SizedBox(height: isLandscape ? 10 : 18),

        // Last Name & First Name — always side by side in landscape
        if (useRows)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                ),
              ),
            ],
          )
        else ...[
          TextFormField(
            controller: _lastNameController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _firstNameController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'First Name *',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
          ),
        ],
        SizedBox(height: gap),

        // In landscape: middle name + birthday side by side
        if (isLandscape)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _middleNameController,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Middle Name (Optional)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: _selectBirthday,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth *',
                      prefixIcon: Icon(Icons.cake_rounded),
                      suffixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(
                      _birthday != null
                          ? '${_birthday!.month}/${_birthday!.day}/${_birthday!.year}  •  Age: ${_calculateAge()}'
                          : 'Tap to select',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _birthday != null ? FontWeight.w700 : FontWeight.w500,
                        color: _birthday != null
                            ? titleColor
                            : (isDark ? AppColors.textDisabled : AppColors.lightTextDisabled),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else ...[
          // Middle Name
          TextFormField(
            controller: _middleNameController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Middle Name (Optional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: gap),

          // Birthday Picker
          InkWell(
            onTap: _selectBirthday,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of Birth *',
                prefixIcon: const Icon(Icons.cake_rounded),
                suffixIcon: const Icon(Icons.calendar_month_rounded),
                errorText: _birthday == null && _formKey1.currentState != null && !_formKey1.currentState!.validate()
                    ? 'Birthday is required'
                    : null,
              ),
              child: Text(
                _birthday != null
                    ? '${_birthday!.month}/${_birthday!.day}/${_birthday!.year}'
                        '  •  Age: ${_calculateAge()} yrs old'
                    : 'Tap to select birthday calendar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _birthday != null ? FontWeight.w700 : FontWeight.w500,
                  color: _birthday != null
                      ? titleColor
                      : (isDark ? AppColors.textDisabled : AppColors.lightTextDisabled),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: gap),

        // Sex & Civil Status — always side by side
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _sex,
                decoration: const InputDecoration(
                  labelText: 'Sex *',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
                dropdownColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.w700, fontSize: 15),
                items: AppConstants.sexOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _sex = v!),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _civilStatus,
                decoration: const InputDecoration(
                  labelText: 'Civil Status *',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                ),
                dropdownColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                style: TextStyle(color: titleColor, fontWeight: FontWeight.w700, fontSize: 15),
                items: AppConstants.civilStatusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _civilStatus = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactStep(bool isDark, bool isCompact, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final gap = isLandscape ? 10.0 : 16.0;

    return Column(
      children: [
        if (isLandscape)
          // In landscape: 2-column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _contactController,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'Contact Number *',
                        prefixIcon: Icon(Icons.phone_rounded),
                        hintText: '09xxxxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact number is required' : null,
                    ),
                    SizedBox(height: gap),
                    TextFormField(
                      controller: _occupationController,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'Occupation (Optional)',
                        prefixIcon: Icon(Icons.work_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'Residential Address *',
                        prefixIcon: Icon(Icons.home_rounded),
                      ),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    SizedBox(height: gap),
                    TextFormField(
                      controller: _referredByController,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        labelText: 'Referred By',
                        prefixIcon: Icon(Icons.person_search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else ...[
          TextFormField(
            controller: _contactController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Mobile Contact Number *',
              prefixIcon: Icon(Icons.phone_rounded),
              hintText: '09xxxxxxxxx',
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact number is required' : null,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _addressController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Complete Residential Address *',
              prefixIcon: Icon(Icons.home_rounded),
            ),
            maxLines: 2,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _occupationController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Occupation (Optional)',
              prefixIcon: Icon(Icons.work_rounded),
            ),
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _referredByController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Referred By (Doctor / Clinic / Self)',
              prefixIcon: Icon(Icons.person_search_rounded),
            ),
          ),
        ],
      ],
    );
  }

  /// ── Past Medical History Section (checkbox-based per clinic form) ──────
  Widget _buildPastMedicalHistorySection(bool isDark, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final cardBg = isDark
        ? AppColors.surfaceLight.withValues(alpha: 0.25)
        : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceHover : AppColors.lightBorder;

    Widget checkItem(String label, bool value, ValueChanged<bool?> onChanged, {Color? accent}) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: accent ?? AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: value ? (accent ?? AppColors.primary) : titleColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Helper to toggle a condition and open the medication dialog when checked
    Future<void> toggleWithMeds(
      String conditionKey,
      bool currentValue,
      ValueSetter<bool> setter,
    ) async {
      final newValue = !currentValue;
      setter(newValue);
      if (newValue && mounted) {
        final result = await showPmhMedicationDialog(
          context,
          conditionName: conditionKey,
          existingMeds: _pmhConditionMeds[conditionKey] ?? [],
          isDark: isDark,
        );
        // null = skipped (keep empty), list = saved meds
        if (result != null) {
          setState(() => _pmhConditionMeds[conditionKey] = result);
        }
      } else if (!newValue) {
        setState(() => _pmhConditionMeds.remove(conditionKey));
      }
    }

    // Condition item: checkbox + inline medication chips + edit button
    Widget conditionItem(
      String label,
      String conditionKey,
      bool value,
      ValueSetter<bool> setter, {
      Color? accent,
    }) {
      final meds = _pmhConditionMeds[conditionKey] ?? [];
      final condAccent = accent ?? AppColors.primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          checkItem(
            label,
            value,
            (v) => toggleWithMeds(conditionKey, value, setter),
            accent: condAccent,
          ),
          if (value) ...[    
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: meds.isEmpty
                        ? Text(
                            'No medications added — tap ✏️ to add',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? AppColors.textDisabled
                                  : AppColors.lightTextDisabled,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: meds
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: condAccent.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: condAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      m,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: condAccent,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  // Pencil — re-open medication dialog
                  GestureDetector(
                    onTap: () async {
                      final result = await showPmhMedicationDialog(
                        context,
                        conditionName: conditionKey,
                        existingMeds: meds,
                        isDark: isDark,
                      );
                      if (result != null && mounted) {
                        setState(() => _pmhConditionMeds[conditionKey] = result);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.edit_rounded,
                          size: 14, color: condAccent.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final leftItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        conditionItem('Hypertension', 'Hypertension', _pmhHypertension,
            (val) => setState(() => _pmhHypertension = val),
            accent: AppColors.urgent),
        const SizedBox(height: 2),
        conditionItem('DM (Diabetes Mellitus)', 'Diabetes Mellitus', _pmhDM,
            (val) => setState(() => _pmhDM = val),
            accent: AppColors.warning),
        const SizedBox(height: 2),
        conditionItem('Allergies', 'Allergies', _pmhAllergies,
            (val) => setState(() => _pmhAllergies = val),
            accent: AppColors.onHold),
      ],
    );

    final rightItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        conditionItem('Operations', 'Operations', _pmhOperations,
            (val) => setState(() => _pmhOperations = val)),
        const SizedBox(height: 2),
        conditionItem('Medications', 'Medications', _pmhMedications,
            (val) => setState(() => _pmhMedications = val)),
        const SizedBox(height: 2),
        conditionItem('Glaucoma', 'Glaucoma', _pmhGlaucoma,
            (val) => setState(() => _pmhGlaucoma = val),
            accent: AppColors.cyanCalm),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Past Medical History',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLandscape)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftItems),
                const SizedBox(width: 24),
                Expanded(child: rightItems),
              ],
            )
          else ...[
            leftItems,
            const SizedBox(height: 4),
            rightItems,
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: _pmhOtherController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Other relevant history',
              hintText: 'Additional notes, surgeries, conditions...',
              prefixIcon: const Icon(Icons.notes_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: isLandscape ? 1 : 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStep(bool isDark, bool isCompact, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final gap = isLandscape ? 10.0 : 16.0;
    // In landscape, reduce max lines to keep form compact
    final maxLines = isLandscape ? 2 : 3;

    return Column(
      children: [
        if (isLandscape)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chiefComplaintController,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Chief Complaint',
                    prefixIcon: Icon(Icons.medical_information_rounded),
                    hintText: 'e.g. Blurred vision...',
                  ),
                  maxLines: maxLines,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _historyIllnessController,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'History of Illness',
                    prefixIcon: Icon(Icons.history_rounded),
                    hintText: 'Onset, duration...',
                  ),
                  maxLines: maxLines,
                ),
              ),
            ],
          )
        else ...[
          TextFormField(
            controller: _chiefComplaintController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Chief Complaint (Primary Concern)',
              prefixIcon: Icon(Icons.medical_information_rounded),
              hintText: 'e.g. Blurred vision, ear pain, recurring tinnitus...',
            ),
            maxLines: maxLines,
          ),
          SizedBox(height: gap),
          TextFormField(
            controller: _historyIllnessController,
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'History of Present Illness',
              prefixIcon: Icon(Icons.history_rounded),
              hintText: 'Onset, duration, symptoms...',
            ),
            maxLines: maxLines,
          ),
        ],
        SizedBox(height: gap),
        _buildPastMedicalHistorySection(isDark, isLandscape),
        SizedBox(height: gap + 6),

        // ── First Time Check-up Question ───────────────────────
        _buildVisitTypeSelector(isDark, isLandscape),
        SizedBox(height: gap + 4),

        // ── Doctor & Room Assignment (Optional) ───────────────
        Text(
          _isFirstTime
              ? 'Assign Doctor & Room (Optional)'
              : 'Assign Doctor & Room (Recommended)',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),

        if (isLandscape)
          Row(
            children: [
              Expanded(child: _buildDoctorField(context, isDark)),
              const SizedBox(width: 14),
              Expanded(child: _buildRoomField(context, isDark)),
            ],
          )
        else ...[
          _buildDoctorField(context, isDark),
          SizedBox(height: gap),
          _buildRoomField(context, isDark),
        ],
      ],
    );
  }

  Widget _buildVisitTypeSelector(bool isDark, bool isLandscape) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.35) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.contact_support_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Is this the patient\'s first time check-up?',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isFirstTime = true),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isFirstTime
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isFirstTime ? AppColors.primary : borderColor,
                      width: _isFirstTime ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFirstTime
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _isFirstTime ? AppColors.primary : subtitleColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yes — First-Time',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _isFirstTime ? AppColors.primary : titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'No doctor for now (optional)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isFirstTime = false),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isFirstTime
                        ? AppColors.cyanCalm.withValues(alpha: 0.15)
                        : cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_isFirstTime ? AppColors.cyanCalm : borderColor,
                      width: !_isFirstTime ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_isFirstTime
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: !_isFirstTime ? AppColors.cyanCalm : subtitleColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No — Past History',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: !_isFirstTime ? AppColors.cyanCalm : titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Assign doctor & room',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (_isFirstTime ? AppColors.primary : AppColors.cyanCalm)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_isFirstTime ? AppColors.primary : AppColors.cyanCalm)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isFirstTime ? Icons.info_outline_rounded : Icons.history_edu_rounded,
                size: 16,
                color: _isFirstTime ? AppColors.primary : AppColors.cyanCalm,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isFirstTime
                      ? 'First-time check-up: Doctor assignment is optional (no doctor needed for now). You may leave Doctor unassigned or assign one if preferred.'
                      : 'Past History Patient: Please select the attending doctor and consultation room for this visit.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _isFirstTime
                        ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                        : (isDark ? AppColors.cyanCalm : const Color(0xFF0E7490)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorField(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.35) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        final hasDoctor = _selectedDoctor != null;

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () async {
              final dept = _selectedConsultationType == 'BOTH' ? null : _selectedConsultationType;
              final doctors = clinic.getDoctors(department: dept);
              final items = doctors
                  .map((d) => PickerItem<Doctor>(
                        value: d,
                        title: d.name,
                        subtitle: d.room != null && d.room!.isNotEmpty
                            ? 'Specialty: ${d.department} • Default Room: ${d.room}'
                            : 'Specialty: ${d.department}',
                        department: d.department,
                        icon: Icons.person_pin_rounded,
                      ))
                  .toList();

              final picked = await showSearchablePicker<Doctor>(
                context,
                title: 'Select Attending Doctor',
                searchHint: 'Search doctor by name or specialty...',
                items: items,
                selectedValue: _selectedDoctor,
                isDark: isDark,
              );

              setState(() {
                _selectedDoctor = picked;
                if (picked != null && picked.room != null && picked.room!.isNotEmpty) {
                  try {
                    _selectedRoom = clinic.rooms.firstWhere(
                      (r) => r.name.toLowerCase() == picked.room!.toLowerCase(),
                    );
                    _roomExplicitlyCleared = false;
                  } catch (_) {}
                }
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasDoctor ? AppColors.primary : borderColor,
                  width: hasDoctor ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDoctor
                              ? _selectedDoctor!.name
                              : (_isFirstTime
                                  ? 'No Doctor For Now (Optional)'
                                  : 'Assign Attending Doctor'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: hasDoctor ? titleColor : subtitleColor,
                          ),
                        ),
                        Text(
                          hasDoctor
                              ? '${_selectedDoctor!.department} Specialist'
                              : (_isFirstTime
                                  ? 'Tap to optionally choose ${_selectedConsultationType == 'BOTH' ? '' : '$_selectedConsultationType '}doctor'
                                  : 'Showing ${_selectedConsultationType == 'BOTH' ? 'all' : _selectedConsultationType} doctors'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasDoctor)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: subtitleColor,
                      onPressed: () => setState(() => _selectedDoctor = null),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomField(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.35) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        if (!_roomExplicitlyCleared && _selectedRoom == null && _selectedConsultationType != 'BOTH') {
          final matchingRooms = clinic.getRooms(department: _selectedConsultationType);
          if (matchingRooms.isNotEmpty) {
            _selectedRoom = matchingRooms.first;
          }
        }
        final hasRoom = _selectedRoom != null;

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () async {
              final dept = _selectedConsultationType == 'BOTH' ? null : _selectedConsultationType;
              final rooms = clinic.getRooms(department: dept);
              final items = rooms
                  .map((r) => PickerItem<ClinicRoom>(
                        value: r,
                        title: r.name,
                        subtitle: 'Department: ${r.department}',
                        department: r.department,
                        icon: Icons.meeting_room_rounded,
                      ))
                  .toList();

              final picked = await showSearchablePicker<ClinicRoom>(
                context,
                title: 'Select Consultation Room',
                searchHint: 'Search room name or number...',
                items: items,
                selectedValue: _selectedRoom,
                isDark: isDark,
              );

              if (picked != null) {
                setState(() {
                  _selectedRoom = picked;
                  _roomExplicitlyCleared = false;
                });
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasRoom ? AppColors.primary : borderColor,
                  width: hasRoom ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cyanCalm.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.door_sliding_rounded,
                        color: AppColors.cyanCalm, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasRoom ? _selectedRoom!.name : 'Assign Room',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: hasRoom ? titleColor : subtitleColor,
                          ),
                        ),
                        Text(
                          hasRoom
                              ? '${_selectedRoom!.name} (${_selectedRoom!.department})'
                              : 'Showing ${_selectedConsultationType == 'BOTH' ? 'all' : _selectedConsultationType} rooms',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRoom)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: subtitleColor,
                      onPressed: () => setState(() {
                        _selectedRoom = null;
                        _roomExplicitlyCleared = true;
                      }),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepButtons(bool isDark) {
    final isLastStep = _currentStep == 3;
    final deptColor = _selectedConsultationType == 'ENT'
        ? AppColors.brandBlue
        : _selectedConsultationType == 'EYES'
            ? AppColors.cyanCalm
            : const Color(0xFF8B5CF6);

    String nextLabel;
    switch (_currentStep) {
      case 0:
        nextLabel = 'Next: Personal Info';
        break;
      case 1:
        nextLabel = 'Next: Contact Details';
        break;
      case 2:
        nextLabel = 'Next: Clinical Intake';
        break;
      default:
        nextLabel = 'Register & Issue Ticket';
    }

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep -= 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleStepForward,
            icon: _isSubmitting
                ? const SizedBox.shrink()
                : Icon(
                    isLastStep ? Icons.confirmation_number_rounded : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
            label: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    nextLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
              backgroundColor: isLastStep ? deptColor : null,
              foregroundColor: isLastStep ? Colors.white : null,
            ),
          ),
        ),
      ],
    );
  }

  void _handleStepForward() {
    // Step 0: Department — no form validation needed, just advance
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey1.currentState!.validate()) return;
      if (_birthday == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select patient date of birth'),
            backgroundColor: AppColors.urgent,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (!_formKey2.currentState!.validate()) return;
      setState(() => _currentStep = 3);
    } else {
      if (!_formKey3.currentState!.validate()) return;
      _submitForm();
    }
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, bool isLandscape) {
    final patient = _registeredPatient!;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    final qrCard = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: patient.patientNo,
            version: QrVersions.auto,
            size: isLandscape ? 140 : 180,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0369A1),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'OFFICIAL OLOF CLINIC QR ID',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0369A1),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            patient.patientNo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );

    final infoContent = Column(
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const OlofLogo(size: 44, showBorder: true),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 6),
              Text(
                'PATIENT REGISTERED SUCCESSFULLY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          patient.displayName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
          ),
          textAlign: isLandscape ? TextAlign.left : TextAlign.center,
        ),
        Text(
          'ID: ${patient.patientNo} • ${patient.age} yrs • ${patient.sex}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
        if (_issuedTickets.isNotEmpty) ...[
          const SizedBox(height: 14),
          // Show each issued ticket as a badge
          ..._issuedTickets.map((t) {
            final tColor = t.department == 'ENT'
                ? AppColors.brandBlue
                : AppColors.cyanCalm;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.department,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: tColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        t.queueNumber,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: tColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (t.doctorName != null)
                        Text(
                          'Dr. ${t.doctorName!}',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ],
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 14),
          Text(
            'Patient can save this QR or ID number for instant check-in.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
            textAlign: isLandscape ? TextAlign.left : TextAlign.center,
          ),
        ],
        const SizedBox(height: 18),

        // Print Ticket Buttons
        if (_issuedTickets.isNotEmpty) ...[
          ..._issuedTickets.map((t) {
            final tColor = t.department == 'ENT'
                ? AppColors.brandBlue
                : AppColors.cyanCalm;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isDarkTheme = context.read<ThemeProvider>().isDarkMode;
                    showQueueTicketPrintDialog(
                      context,
                      isDark: isDarkTheme,
                      ticket: t,
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: Text('Print ${t.department} Ticket  •  ${t.queueNumber}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: tColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 2),
        ],

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/receptionist'),
                icon: const Icon(Icons.people_alt_rounded, size: 18),
                label: const Text('Go to Queue'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/receptionist'),
                icon: const Icon(Icons.dashboard_rounded, size: 18),
                label: const Text('Dashboard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _registeredPatient = null;
                _issuedTickets.clear();
                _currentStep = 0;
                _selectedConsultationType = 'ENT';
                _firstNameController.clear();
                _lastNameController.clear();
                _middleNameController.clear();
                _addressController.clear();
                _contactController.clear();
                _occupationController.clear();
                _referredByController.clear();
                _chiefComplaintController.clear();
                _historyIllnessController.clear();
                _pastMedicalController.clear();
                _pmhOtherController.clear();
                _birthday = null;
                _selectedDoctor = null;
                _roomExplicitlyCleared = false;
                _didAutoAssignInitialRoom = false;
                final clinic = context.read<ClinicProvider>();
                final matchingRooms = clinic.getRooms(department: 'ENT');
                _selectedRoom = matchingRooms.isNotEmpty ? matchingRooms.first : null;
                _photoBytes = null;
                _photoFileName = 'photo.jpg';
                _pmhHypertension = false;
                _pmhDM = false;
                _pmhAllergies = false;
                _pmhOperations = false;
                _pmhMedications = false;
                _pmhGlaucoma = false;
                _pmhConditionMeds.clear();
              });
            },
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text('Register Another Patient'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 24 : 16,
          vertical: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      qrCard,
                      const SizedBox(width: 24),
                      Expanded(child: infoContent),
                    ],
                  )
                : Column(
                    children: [
                      qrCard,
                      const SizedBox(height: 20),
                      infoContent,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  int _calculateAge() {
    if (_birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthday!.year;
    if (now.month < _birthday!.month ||
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _submitForm() async {
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a birthday')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Capture providers before any async gaps (use_build_context_synchronously)
      final patientProv = context.read<PatientProvider>();
      final queueProv = context.read<QueueProvider>();

      // Prepare structured PMH conditions and formatted medication summary
      final conditions = <PmhCondition>[];
      if (_pmhHypertension) {
        conditions.add(PmhCondition(
            condition: 'Hypertension',
            medications: _pmhConditionMeds['Hypertension'] ?? []));
      }
      if (_pmhDM) {
        conditions.add(PmhCondition(
            condition: 'Diabetes Mellitus',
            medications: _pmhConditionMeds['Diabetes Mellitus'] ?? []));
      }
      if (_pmhAllergies) {
        conditions.add(PmhCondition(
            condition: 'Allergies',
            medications: _pmhConditionMeds['Allergies'] ?? []));
      }
      if (_pmhOperations) {
        conditions.add(PmhCondition(
            condition: 'Operations',
            medications: _pmhConditionMeds['Operations'] ?? []));
      }
      if (_pmhMedications) {
        conditions.add(PmhCondition(
            condition: 'Medications',
            medications: _pmhConditionMeds['Medications'] ?? []));
      }
      if (_pmhGlaucoma) {
        conditions.add(PmhCondition(
            condition: 'Glaucoma',
            medications: _pmhConditionMeds['Glaucoma'] ?? []));
      }

      final otherText = _pmhOtherController.text.trim().isNotEmpty
          ? _pmhOtherController.text.trim()
          : null;
      final formattedPmh = PmhCondition.formatList(conditions, otherText);

      final patient = await patientProv.registerPatient(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            middleName: _middleNameController.text.trim().isNotEmpty
                ? _middleNameController.text.trim()
                : null,
            birthday: _birthday!,
            sex: _sex,
            civilStatus: _civilStatus,
            address: _addressController.text.trim(),
            contactNumber: _contactController.text.trim(),
            occupation: _occupationController.text.trim().isNotEmpty
                ? _occupationController.text.trim()
                : null,
            referredBy: _referredByController.text.trim().isNotEmpty
                ? _referredByController.text.trim()
                : null,
            chiefComplaint: _chiefComplaintController.text.trim().isNotEmpty
                ? _chiefComplaintController.text.trim()
                : null,
            historyOfPresentIllness:
                _historyIllnessController.text.trim().isNotEmpty
                    ? _historyIllnessController.text.trim()
                    : null,
            pastMedicalHistory: formattedPmh.isNotEmpty ? formattedPmh : null,
            isFirstTime: _isFirstTime,
            assignedDoctor: _selectedDoctor?.name,
            assignedRoom: _selectedRoom?.name,
          );

      // Upload photo if one was selected
      if (_photoBytes != null && mounted) {
        await patientProv.uploadPatientPhoto(
              patient.id,
              _photoBytes!,
              _photoFileName,
            );
      }

      // ── Always issue queue tickets based on selected consultation type ──
      final deptsToPrint = _selectedConsultationType == 'BOTH'
          ? ['ENT', 'EYES']
          : [_selectedConsultationType];

      final issuedTickets = <QueueTicketData>[];

      for (final dept in deptsToPrint) {
        String queueNum = 'REG-000';
        try {
          final entry = await queueProv.addToQueue(
            patientId: patient.id,
            patientName: patient.displayName,
            patientPhoto: patient.photoUrl,
            department: dept,
            purpose: 'Consultation',
            doctor: _selectedDoctor?.name,
            room: _selectedRoom?.name,
          );
          queueNum = entry.queueNumber;
          issuedTickets.add(QueueTicketData(
            queueNumber: entry.queueNumber,
            patientName: patient.displayName,
            department: dept,
            doctorName: _selectedDoctor?.name,
            roomName: _selectedRoom?.name,
            purpose: 'Consultation',
          ));
        } catch (queueErr) {
          debugPrint('Queue error for $dept: $queueErr');
        }

        // Save dept record
        try {
          await _deptRepo.create(
            patientId: patient.id,
            department: dept,
            chiefComplaint: _chiefComplaintController.text.trim().isNotEmpty
                ? _chiefComplaintController.text.trim()
                : null,
            historyOfPresentIllness:
                _historyIllnessController.text.trim().isNotEmpty
                    ? _historyIllnessController.text.trim()
                    : null,
            pmhConditions: conditions,
            pastMedicalHistory: formattedPmh.isNotEmpty ? formattedPmh : null,
            isFirstTime: _isFirstTime,
            assignedDoctor: _selectedDoctor?.name,
            assignedRoom: _selectedRoom?.name,
          );
        } catch (deptErr) {
          debugPrint('Dept record save error for $dept (non-fatal): $deptErr');
        }

        // Save visit record so it immediately shows in Visit History
        try {
          final visitRecord = VisitRecord(
            id: IdGenerator.generateUuid(),
            patientId: patient.id,
            department: dept,
            purpose: 'Registered - Consultation',
            chiefComplaint: _chiefComplaintController.text.trim().isNotEmpty
                ? _chiefComplaintController.text.trim()
                : null,
            assignedDoctor: _selectedDoctor?.name,
            assignedRoom: _selectedRoom?.name,
            notes: [
              'Registered at reception.',
              if (_selectedDoctor != null) 'Doctor: ${_selectedDoctor!.name}',
              if (_selectedRoom != null) 'Room: ${_selectedRoom!.name}',
            ].join(' • '),
            queueNumber: queueNum,
            visitDate: DateTime.now(),
          );
          await patientProv.addVisitRecord(visitRecord);
        } catch (visitErr) {
          debugPrint('Visit record save error for $dept (non-fatal): $visitErr');
        }
      }

      setState(() {
        _registeredPatient = patient;
        _issuedTickets
          ..clear()
          ..addAll(issuedTickets);
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering patient: $e')),
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    final themeProv = context.read<ThemeProvider>();
    final source = await showPhotoSourceDialog(
      context,
      isDark: themeProv.isDarkMode,
    );
    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoFileName = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }
}
