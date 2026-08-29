import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/patient_provider.dart';
import '../../data/models/patient.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';

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
    // Use side-by-side rows in landscape OR on wide screens
    final useRows = !isCompact || isLandscape;
    final gap = isLandscape ? 12.0 : 16.0;

    return Column(
      children: [
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
        TextFormField(
          controller: _pastMedicalController,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            labelText: 'Past Medical & Surgical History',
            prefixIcon: Icon(Icons.medical_services_rounded),
            hintText: 'Hypertension, diabetes, allergies, surgeries...',
          ),
          maxLines: maxLines,
        ),
      ],
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
        const SizedBox(height: 16),
        Row(
          mainAxisSize: isLandscape ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                    '/receptionist/checkin?patientId=${patient.id}'),
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
            pastMedicalHistory: _pastMedicalController.text.trim().isNotEmpty
                ? _pastMedicalController.text.trim()
                : null,
          );

      setState(() {
        _registeredPatient = patient;
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
}
