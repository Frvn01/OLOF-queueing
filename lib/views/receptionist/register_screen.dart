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
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../data/models/doctor.dart';
import '../../data/models/clinic_room.dart';
import '../../shared/widgets/photo_source_dialog.dart';
import '../../shared/widgets/searchable_picker_dialog.dart';
import '../../providers/queue_provider.dart';
import 'widgets/clinic_management_dialog.dart';

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
  int _currentStep = 0;

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
  String? _registeredQueueNumber;

  // Photo picker state
  Uint8List? _photoBytes;
  String _photoFileName = 'photo.jpg';
  final ImagePicker _picker = ImagePicker();

  // Doctor & Room selection state
  bool _isFirstTime = true;
  Doctor? _selectedDoctor;
  ClinicRoom? _selectedRoom;

  // Past Medical History checkboxes
  bool _pmhHypertension = false;
  bool _pmhDM = false;
  bool _pmhAllergies = false;
  bool _pmhOperations = false;
  bool _pmhMedications = false;
  bool _pmhGlaucoma = false;
  final _pmhOtherController = TextEditingController();

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
                      Form(
                        key: _formKey1,
                        child: _buildPersonalInfoStep(isDark, isCompact, isLandscape),
                      )
                    else if (_currentStep == 1)
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
      {'num': '1', 'title': 'Personal'},
      {'num': '2', 'title': 'Contact'},
      {'num': '3', 'title': 'Clinical'},
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
        title = 'Personal Information';
        subtitle = 'Legal full name, date of birth, biological sex & status';
        icon = Icons.badge_rounded;
        break;
      case 1:
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

    final leftItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        checkItem('Hypertension', _pmhHypertension, (v) => setState(() => _pmhHypertension = v!), accent: AppColors.urgent),
        const SizedBox(height: 2),
        checkItem('DM (Diabetes Mellitus)', _pmhDM, (v) => setState(() => _pmhDM = v!), accent: AppColors.warning),
        const SizedBox(height: 2),
        checkItem('Allergies', _pmhAllergies, (v) => setState(() => _pmhAllergies = v!), accent: AppColors.onHold),
      ],
    );

    final rightItems = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        checkItem('Operations', _pmhOperations, (v) => setState(() => _pmhOperations = v!)),
        const SizedBox(height: 2),
        checkItem('Medications', _pmhMedications, (v) => setState(() => _pmhMedications = v!)),
        const SizedBox(height: 2),
        checkItem('Glaucoma', _pmhGlaucoma, (v) => setState(() => _pmhGlaucoma = v!), accent: AppColors.cyanCalm),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            TextButton.icon(
              onPressed: () => showClinicManagementDialog(context, isDark: isDark),
              icon: const Icon(Icons.settings_rounded, size: 14),
              label: const Text('Clinic Setup'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
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
              final doctors = clinic.getDoctors();
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
                addNewLabel: '+ Add Doctor',
                onAddNew: () => showClinicManagementDialog(context, isDark: isDark, initialTab: 0),
              );

              setState(() {
                _selectedDoctor = picked;
                if (picked != null && _selectedRoom == null && picked.room != null) {
                  try {
                    _selectedRoom = clinic.rooms.firstWhere(
                      (r) => r.name.toLowerCase() == picked.room!.toLowerCase(),
                    );
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
                                  ? 'Tap to optionally choose doctor, or leave unassigned'
                                  : 'Filter with search & department'),
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
        final hasRoom = _selectedRoom != null;

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () async {
              final rooms = clinic.getRooms();
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
                addNewLabel: '+ Add Room',
                onAddNew: () => showClinicManagementDialog(context, isDark: isDark, initialTab: 1),
              );

              setState(() => _selectedRoom = picked);
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
                              : 'Filter with search & department',
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
                      onPressed: () => setState(() => _selectedRoom = null),
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
                    _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
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
                    _currentStep == 0
                        ? 'Next: Contact Info'
                        : _currentStep == 1
                            ? 'Next: Medical Intake'
                            : 'Complete Registration',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
            ),
          ),
        ),
      ],
    );
  }

  void _handleStepForward() {
    if (_currentStep == 0) {
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
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey2.currentState!.validate()) return;
      setState(() => _currentStep = 2);
    } else {
      if (!_formKey3.currentState!.validate()) return;
      _submitForm();
    }
  }

  Widget _buildSuccessView(BuildContext context, bool isDark, bool isLandscape) {
    final patient = _registeredPatient!;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final qrCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            size: isLandscape ? 130 : 180,
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
          const SizedBox(height: 6),
          const Text(
            'OFFICIAL OLOF CLINIC QR ID',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0369A1),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );

    final infoSection = Column(
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const OlofLogo(size: 48, showBorder: true),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 5),
              Text(
                'PATIENT REGISTERED',
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
          ),
          textAlign: isLandscape ? TextAlign.left : TextAlign.center,
        ),
        Text(
          'ID: ${patient.patientNo}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: subtitleColor,
          ),
        ),
        if (_registeredQueueNumber != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.nowServing.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.nowServing, width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'QUEUE TICKET ISSUED',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.nowServingTextDark,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _registeredQueueNumber!,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.nowServingTextDark,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Doctor: ${_selectedDoctor?.name ?? patient.assignedDoctor} • Room: ${_selectedRoom?.name ?? patient.assignedRoom}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Automatically Added to Live Queue',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Text(
            'Patient can save this QR or their ID number for instant check-in.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
            textAlign: isLandscape ? TextAlign.left : TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisSize: isLandscape ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (_registeredQueueNumber != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/secretary'),
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                  label: const Text('Secretary Station'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
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
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final doctorParam = Uri.encodeComponent(_selectedDoctor?.name ?? patient.assignedDoctor ?? '');
                    final roomParam = Uri.encodeComponent(_selectedRoom?.name ?? patient.assignedRoom ?? '');
                    final deptParam = Uri.encodeComponent(_selectedDoctor?.department ?? '');
                    context.go(
                        '/receptionist/checkin?patientId=${patient.id}&doctor=$doctorParam&room=$roomParam&dept=$deptParam');
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
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
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 20 : 24,
          vertical: isLandscape ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    qrCard,
                    const SizedBox(width: 24),
                    Expanded(child: infoSection),
                  ],
                )
              : infoSection,
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
      final patient = await context.read<PatientProvider>().registerPatient(
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
            pastMedicalHistory: () {
                final parts = <String>[];
                if (_pmhHypertension) parts.add('Hypertension');
                if (_pmhDM) parts.add('DM');
                if (_pmhAllergies) parts.add('Allergies');
                if (_pmhOperations) parts.add('Operations');
                if (_pmhMedications) parts.add('Medications');
                if (_pmhGlaucoma) parts.add('Glaucoma');
                if (_pmhOtherController.text.trim().isNotEmpty) {
                  parts.add(_pmhOtherController.text.trim());
                }
                return parts.isEmpty ? null : parts.join(', ');
              }(),
            isFirstTime: _isFirstTime,
            assignedDoctor: _selectedDoctor?.name,
            assignedRoom: _selectedRoom?.name,
          );

      // Upload photo if one was selected
      if (_photoBytes != null && mounted) {
        await context.read<PatientProvider>().uploadPatientPhoto(
              patient.id,
              _photoBytes!,
              _photoFileName,
            );
      }

      // If doctor and assigned room already chosen: automatically add to queue!
      String? autoQueueNumber;
      if (_selectedDoctor != null && _selectedRoom != null && mounted) {
        final dept = _selectedDoctor!.department == 'BOTH'
            ? 'ENT'
            : _selectedDoctor!.department;
        try {
          final entry = await context.read<QueueProvider>().addToQueue(
                patientId: patient.id,
                patientName: patient.displayName,
                patientPhoto: patient.photoUrl,
                department: dept,
                purpose: 'Consultation',
                doctor: _selectedDoctor!.name,
                room: _selectedRoom!.name,
              );
          autoQueueNumber = entry.queueNumber;
        } catch (queueErr) {
          debugPrint('Auto queue addition error: $queueErr');
        }
      }

      setState(() {
        _registeredPatient = patient;
        _registeredQueueNumber = autoQueueNumber;
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
