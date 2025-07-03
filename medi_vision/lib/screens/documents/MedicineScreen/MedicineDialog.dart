import 'package:flutter/material.dart';
import '../../../consts/themes.dart';
import 'model/medicines_model.dart';

class MedicineDialog extends StatefulWidget {
  final Medicine? medicine;

  const MedicineDialog({super.key, this.medicine});

  @override
  _MedicineDialogState createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<MedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _genericNameController;
  late final TextEditingController _strengthController;
  late final TextEditingController _usesController;
  late final TextEditingController _dosageAdultsController;
  late final TextEditingController _dosageChildrenController;
  late final TextEditingController _dosageMaxDailyController;
  late final TextEditingController _sideEffectsCommonController;
  late final TextEditingController _sideEffectsSeriousController;
  late final TextEditingController _precautionsController;
  late final TextEditingController _interactionsController;
  late final TextEditingController _warningsController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _typeController;
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing medicine data or empty strings
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _genericNameController = TextEditingController(text: widget.medicine?.genericName ?? '');
    _strengthController = TextEditingController(text: widget.medicine?.strength ?? '');
    _usesController = TextEditingController(
        text: widget.medicine?.uses?.join(', ') ?? '');
    _dosageAdultsController = TextEditingController(
        text: widget.medicine?.dosage?.adults ?? '');
    _dosageChildrenController = TextEditingController(
        text: widget.medicine?.dosage?.children ?? '');
    _dosageMaxDailyController = TextEditingController(
        text: widget.medicine?.dosage?.maxDaily ?? '');
    _sideEffectsCommonController = TextEditingController(
        text: widget.medicine?.sideEffects?.common?.join(', ') ?? '');
    _sideEffectsSeriousController = TextEditingController(
        text: widget.medicine?.sideEffects?.serious?.join(', ') ?? '');
    _precautionsController = TextEditingController(
        text: widget.medicine?.precautions?.join(', ') ?? '');
    _interactionsController = TextEditingController(
        text: widget.medicine?.interactions?.join(', ') ?? '');
    _warningsController = TextEditingController(
        text: widget.medicine?.warnings?.join(', ') ?? '');
    _frequencyController = TextEditingController(text: widget.medicine?.frequency ?? '');
    _typeController = TextEditingController(text: widget.medicine?.type ?? '');
    _durationController = TextEditingController(text: widget.medicine?.duration ?? '');
    _instructionsController = TextEditingController(text: widget.medicine?.instructions ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _genericNameController.dispose();
    _strengthController.dispose();
    _usesController.dispose();
    _dosageAdultsController.dispose();
    _dosageChildrenController.dispose();
    _dosageMaxDailyController.dispose();
    _sideEffectsCommonController.dispose();
    _sideEffectsSeriousController.dispose();
    _precautionsController.dispose();
    _interactionsController.dispose();
    _warningsController.dispose();
    _frequencyController.dispose();
    _typeController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium)),
      elevation: 4,
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(theme),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildFormFields(theme),
                const SizedBox(height: AppDimensions.paddingLarge),
                _buildActionButtons(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the dialog title
  Widget _buildTitle(ThemeData theme) {
    return Text(
      widget.medicine == null ? 'Add Medicine' : 'Edit Medicine',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  // Builds all form fields
  Widget _buildFormFields(ThemeData theme) {
    return Column(
      children: [
        _buildInputField(
          controller: _nameController,
          label: 'Medicine Name',
          icon: Icons.medical_services,
          validator: (v) => v!.isEmpty ? 'Medicine name is required' : null,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _genericNameController,
          label: 'Generic Name (Optional)',
          icon: Icons.label,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _strengthController,
          label: 'Strength (Optional)',
          icon: Icons.fitness_center,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _usesController,
          label: 'Uses (Optional, comma-separated)',
          icon: Icons.info,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _dosageAdultsController,
          label: 'Dosage - Adults (Optional)',
          icon: Icons.person,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _dosageChildrenController,
          label: 'Dosage - Children (Optional)',
          icon: Icons.child_care,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _dosageMaxDailyController,
          label: 'Max Daily Dosage (Optional)',
          icon: Icons.schedule,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _sideEffectsCommonController,
          label: 'Common Side Effects (Optional, comma-separated)',
          icon: Icons.warning,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _sideEffectsSeriousController,
          label: 'Serious Side Effects (Optional, comma-separated)',
          icon: Icons.error,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _precautionsController,
          label: 'Precautions (Optional, comma-separated)',
          icon: Icons.security,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _interactionsController,
          label: 'Interactions (Optional, comma-separated)',
          icon: Icons.link,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _warningsController,
          label: 'Warnings (Optional, comma-separated)',
          icon: Icons.announcement,
          theme: theme,
          maxLines: 2,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _frequencyController,
          label: 'Frequency (Optional)',
          icon: Icons.access_time,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _typeController,
          label: 'Type (Optional)',
          icon: Icons.category,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _durationController,
          label: 'Duration (Optional)',
          icon: Icons.calendar_today,
          theme: theme,
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildInputField(
          controller: _instructionsController,
          label: 'Instructions (Optional)',
          icon: Icons.note,
          maxLines: 3,
          theme: theme,
        ),
      ],
    );
  }

  // Builds a single input field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.background,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
    );
  }

  // Builds action buttons (Cancel and Add/Save)
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            foregroundColor: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
          ),
          onPressed: _submitForm,
          child: Text(widget.medicine == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  // Submits the form and returns a Medicine object
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final medicine = Medicine(
        name: _nameController.text.trim(),
        genericName: _genericNameController.text.trim().isNotEmpty
            ? _genericNameController.text.trim()
            : null,
        strength: _strengthController.text.trim().isNotEmpty
            ? _strengthController.text.trim()
            : null,
        uses: _usesController.text.trim().isNotEmpty
            ? _usesController.text.split(',').map((e) => e.trim()).toList()
            : null,
        dosage: (_dosageAdultsController.text.trim().isNotEmpty ||
            _dosageChildrenController.text.trim().isNotEmpty ||
            _dosageMaxDailyController.text.trim().isNotEmpty)
            ? Dosage(
          adults: _dosageAdultsController.text.trim().isNotEmpty
              ? _dosageAdultsController.text.trim()
              : null,
          children: _dosageChildrenController.text.trim().isNotEmpty
              ? _dosageChildrenController.text.trim()
              : null,
          maxDaily: _dosageMaxDailyController.text.trim().isNotEmpty
              ? _dosageMaxDailyController.text.trim()
              : null,
        )
            : null,
        sideEffects: (_sideEffectsCommonController.text.trim().isNotEmpty ||
            _sideEffectsSeriousController.text.trim().isNotEmpty)
            ? SideEffects(
          common: _sideEffectsCommonController.text.trim().isNotEmpty
              ? _sideEffectsCommonController.text
              .split(',')
              .map((e) => e.trim())
              .toList()
              : null,
          serious: _sideEffectsSeriousController.text.trim().isNotEmpty
              ? _sideEffectsSeriousController.text
              .split(',')
              .map((e) => e.trim())
              .toList()
              : null,
        )
            : null,
        precautions: _precautionsController.text.trim().isNotEmpty
            ? _precautionsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        interactions: _interactionsController.text.trim().isNotEmpty
            ? _interactionsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        warnings: _warningsController.text.trim().isNotEmpty
            ? _warningsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        frequency: _frequencyController.text.trim().isNotEmpty
            ? _frequencyController.text.trim()
            : null,
        type: _typeController.text.trim().isNotEmpty
            ? _typeController.text.trim()
            : null,
        duration: _durationController.text.trim().isNotEmpty
            ? _durationController.text.trim()
            : null,
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
      );
      Navigator.pop(context, medicine);
    }
  }
}