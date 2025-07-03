import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../consts/themes.dart';
import 'MedicineDialog.dart';
import 'model/medicines_model.dart';
import '../../../services/pdf_service.dart';
import 'consts/medicine_card.dart';

class MedicineScanPage extends StatelessWidget {
  final Map<String, dynamic> scanData;
  final File imageFile;

  const MedicineScanPage({
    super.key,
    required this.scanData,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicineScanController(
        scanData: scanData,
        imageFile: imageFile,
        userData: {},
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _MedicineScanContent(imageFile: imageFile),
      ),
    );
  }
}

class _MedicineScanContent extends StatelessWidget {
  final File imageFile;

  const _MedicineScanContent({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<MedicineScanController>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Prescription Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pinned: true,
          floating: true,
          snap: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'Search Medicine',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => controller.sharePDF(context),
              tooltip: 'Share Prescription',
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescription Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Prescription Summary',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${controller.medicines.length} ${controller.medicines.length == 1 ? 'Medicine' : 'Medicines'}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now()),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        if (controller.scanData['doctorName'] != null ||
                            controller.scanData['patientName'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (controller.scanData['doctorName'] != null)
                                  _buildInfoRow(
                                    context,
                                    'Doctor',
                                    controller.scanData['doctorName']!,
                                    Icons.person,
                                  ),
                                if (controller.scanData['patientName'] != null)
                                  _buildInfoRow(
                                    context,
                                    'Patient',
                                    controller.scanData['patientName']!,
                                    Icons.accessible,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Medicines Section
                _buildSectionHeader(
                  context,
                  'Extracted Medicines',
                  controller.medicines.isNotEmpty
                      ? ValueListenableBuilder<bool>(
                    valueListenable: controller.isFetchingDetails,
                    builder: (context, isFetching, _) {
                      return ElevatedButton.icon(
                        icon: isFetching
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                            : const Icon(Icons.cloud_download, size: 18),
                        label: Text(
                          isFetching ? 'Fetching...' : 'Fetch Details',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: isFetching
                            ? null
                            : () => controller.fetchAllMedicineDetails(context),
                      );
                    },
                  )
                      : null,
                ),
                const SizedBox(height: 8),
                controller.medicines.isEmpty
                    ? _buildEmptyState(
                  context,
                  'No medicines found',
                  'Try adding medicines manually or check the extracted text',
                  Icons.medication,
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.medicines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return MedicineCard(
                      medicine: controller.medicines[index],
                      onEdit: () => controller.editMedicineDialog(
                          controller.medicines[index], index, context),
                      onDelete: () => controller.deleteMedicine(
                          controller.medicines[index], context),
                      onTap: () => controller.showMedicineDetails(
                          controller.medicines[index], context),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Extracted Text Section
                _buildSectionHeader(context, 'Extracted Text'),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      controller.scanData['extracted_text']?.toString() ??
                          'No text extracted from the image',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Add Medicine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => controller.addMedicineDialog(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: controller.isGeneratingPDF,
                      builder: (context, isGenerating, _) {
                        return ElevatedButton.icon(
                          icon: isGenerating
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : const Icon(Icons.picture_as_pdf, size: 20),
                          label: Text(
                            isGenerating ? 'Exporting...' : 'Export PDF',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: isGenerating
                              ? null
                              : () => controller.generateAndSavePDF(context),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, [Widget? action]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    final controller = context.read<MedicineScanController>();
    final searchController = TextEditingController();
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Medicine',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Enter medicine name',
            labelStyle: theme.textTheme.bodyMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          autofocus: true,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            onPressed: () async {
              final medicineName = searchController.text.trim();
              if (medicineName.isNotEmpty) {
                Navigator.pop(context);
                await controller.fetchMedicineDetails(medicineName, context);
              }
            },
            child: Text(
              'Search',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class MedicineScanController with ChangeNotifier {
  File? imageFile;
  final Map<String, dynamic> scanData;
  final Map<String, dynamic> userData;
  final ValueNotifier<bool> isGeneratingPDF = ValueNotifier(false);
  final ValueNotifier<bool> isFetchingDetails = ValueNotifier(false);
  final TextEditingController _pdfNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();

  final List<Medicine> _medicines = [];
  List<Medicine> get medicines => List.unmodifiable(_medicines);

  // Track which medicines have been fetched to prevent duplicate fetches
  final Set<String> _fetchedMedicines = {};

  MedicineScanController({
    required this.scanData,
    required this.userData,
    this.imageFile,
  }) {
    _initializeMedicines();
    _doctorNameController.text = scanData['doctorName'] ?? '';
    _patientNameController.text = scanData['patientName'] ?? '';
    _pdfNameController.text =
    'Prescription_${DateFormat('yyyyMMdd').format(DateTime.now())}';
  }

  void _initializeMedicines() {
    if (scanData['medicines'] != null) {
      try {
        for (var med in scanData['medicines'] as List<dynamic>) {
          if (med is Map<String, dynamic>) {
            _medicines.add(Medicine.fromMap(med));
          } else if (med is String) {
            _medicines.add(Medicine(name: med));
          }
        }
      } catch (e) {
        debugPrint('Error initializing medicines: $e');
        _handleLegacyMedicineData();
      }
    }
  }

  void _handleLegacyMedicineData() {
    _medicines.clear();
    try {
      if (scanData['medicines'] is String) {
        _medicines.add(Medicine(name: scanData['medicines'] as String));
      } else if (scanData['medicines'] is List) {
        for (var item in scanData['medicines'] as List) {
          if (item is String) {
            _medicines.add(Medicine(name: item));
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to handle legacy medicine data: $e');
    }
  }

  @override
  void dispose() {
    isGeneratingPDF.dispose();
    isFetchingDetails.dispose();
    _pdfNameController.dispose();
    _doctorNameController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> addMedicineDialog(BuildContext context) async {
    if (!context.mounted) return;

    final result = await showDialog<Medicine>(
      context: context,
      builder: (_) => const MedicineDialog(),
    );

    if (result != null && context.mounted) {
      _medicines.add(result);
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${result.name} to prescription'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> editMedicineDialog(
      Medicine medicine, int index, BuildContext context) async {
    final result = await showDialog<Medicine>(
      context: context,
      builder: (_) => MedicineDialog(medicine: medicine),
    );
    if (result != null) {
      _medicines[index] = result;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> deleteMedicine(Medicine medicine, BuildContext context) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete ${medicine.name}?',
          style: TextStyle(color: Colors.red.shade700),
        ),
        content: Text('Are you sure you want to delete ${medicine.name} from the prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    if (shouldDelete ?? false) {
      final name = medicine.name;
      _medicines.remove(medicine);
      _fetchedMedicines.remove(name); // Remove from fetched set if it was there
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $name from prescription'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> showMedicineDetails(Medicine medicine, BuildContext context) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        medicine.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (medicine.genericName != null)
                _buildDetailRow('Generic Name', medicine.genericName!, Icons.medication),
              if (medicine.strength != null)
                _buildDetailRow('Strength', medicine.strength!, Icons.fitness_center),
              if (medicine.uses != null)
                _buildDetailRow('Uses', medicine.uses!.join(', '), Icons.healing),
              if (medicine.dosage != null) ...[
                _buildDetailRow('Dosage (Adults)', medicine.dosage!.adults ?? 'N/A', Icons.people),
                _buildDetailRow('Dosage (Children)', medicine.dosage!.children ?? 'N/A', Icons.child_care),
                _buildDetailRow('Max Daily', medicine.dosage!.maxDaily ?? 'N/A', Icons.warning),
              ],
              if (medicine.sideEffects != null) ...[
                if (medicine.sideEffects!.common != null)
                  _buildDetailRow('Common Side Effects', medicine.sideEffects!.common!.join(', '), Icons.info),
                if (medicine.sideEffects!.serious != null)
                  _buildDetailRow('Serious Side Effects', medicine.sideEffects!.serious!.join(', '), Icons.warning_amber),
              ],
              if (medicine.precautions != null)
                _buildDetailRow('Precautions', medicine.precautions!.join(', '), Icons.health_and_safety),
              if (medicine.interactions != null)
                _buildDetailRow('Interactions', medicine.interactions!.join(', '), Icons.link),
              if (medicine.warnings != null)
                _buildDetailRow('Warnings', medicine.warnings!.join(', '), Icons.warning),
              if (medicine.frequency != null)
                _buildDetailRow('Frequency', medicine.frequency!, Icons.schedule),
              if (medicine.type != null)
                _buildDetailRow('Type', medicine.type!, Icons.category),
              if (medicine.duration != null)
                _buildDetailRow('Duration', medicine.duration!, Icons.calendar_today),
              if (medicine.instructions != null)
                _buildDetailRow('Instructions', medicine.instructions!, Icons.list),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchMedicineDetails(String medicineName, BuildContext context) async {
    if (!context.mounted) return;

    try {
      final url = Uri.parse("http://10.1.31.11:8000/medicine-info");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "medicine_name": medicineName,
          "get_all": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final medicine = Medicine.fromMap(data);

        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  if (medicine.genericName != null)
                    _buildDetailRow('Generic Name', medicine.genericName!, Icons.medication),
                  if (medicine.strength != null)
                    _buildDetailRow('Strength', medicine.strength!, Icons.fitness_center),
                  if (medicine.uses != null)
                    _buildDetailRow('Uses', medicine.uses!.join(', '), Icons.healing),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _medicines.add(medicine);
                            _fetchedMedicines.add(medicine.name); // Mark as fetched
                            notifyListeners();
                            Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added ${medicine.name} to prescription'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Add to Prescription'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to fetch details: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchAllMedicineDetails(BuildContext context) async {
    if (!context.mounted || isFetchingDetails.value) return;

    isFetchingDetails.value = true;
    try {
      for (var i = 0; i < _medicines.length; i++) {
        final medicine = _medicines[i];

        // Skip if we've already fetched details for this medicine
        if (_fetchedMedicines.contains(medicine.name)) continue;

        // Skip if the medicine already has complete information
        if (_hasCompleteDetails(medicine)) {
          _fetchedMedicines.add(medicine.name);
          continue;
        }

        final url = Uri.parse("http://10.1.31.11:8000/medicine-info");
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "medicine_name": medicine.name,
            "get_all": false,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final updatedMedicine = Medicine.fromMap(data);

          // Merge existing data with new data, preserving any existing fields
          _medicines[i] = _mergeMedicineDetails(medicine, updatedMedicine);
          _fetchedMedicines.add(medicine.name); // Mark as fetched
          notifyListeners();
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to fetch details for ${medicine.name}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully updated medicine details'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isFetchingDetails.value = false;
    }
  }

  // Check if medicine already has complete details
  bool _hasCompleteDetails(Medicine medicine) {
    return medicine.genericName != null &&
        medicine.strength != null &&
        medicine.uses != null &&
        medicine.dosage != null;
  }

  // Merge existing medicine details with new details, preserving existing data
  Medicine _mergeMedicineDetails(Medicine existing, Medicine updated) {
    return Medicine(
      name: existing.name,
      genericName: updated.genericName ?? existing.genericName,
      strength: updated.strength ?? existing.strength,
      uses: updated.uses ?? existing.uses,
      dosage: updated.dosage ?? existing.dosage,
      sideEffects: updated.sideEffects ?? existing.sideEffects,
      precautions: updated.precautions ?? existing.precautions,
      interactions: updated.interactions ?? existing.interactions,
      warnings: updated.warnings ?? existing.warnings,
      frequency: updated.frequency ?? existing.frequency,
      type: updated.type ?? existing.type,
      duration: updated.duration ?? existing.duration,
      instructions: updated.instructions ?? existing.instructions,
    );
  }

  Future<void> searchMedicineDetails(String medicineName, BuildContext context) async {
    final index = _medicines.indexWhere(
            (m) => m.name.toLowerCase().contains(medicineName.toLowerCase()));
    if (index != -1 && context.mounted) {
      await showMedicineDetails(_medicines[index], context);
    } else if (context.mounted) {
      await fetchMedicineDetails(medicineName, context);
    }
  }

  Future<void> generateAndSavePDF(BuildContext context) async {
    isGeneratingPDF.value = true;
    try {
      final file = await PDFService.generatePDF(
        medicines: _medicines,
        imageFile: imageFile,
        fileName: _pdfNameController.text,
        doctorName:
        _doctorNameController.text.isEmpty ? null : _doctorNameController.text,
        patientName:
        _patientNameController.text.isEmpty ? null : _patientNameController.text,
        extractedText: scanData['extracted_text']?.toString(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      isGeneratingPDF.value = false;
    }
  }

  Future<void> sharePDF(BuildContext context) async {
    isGeneratingPDF.value = true;
    try {
      final file = await PDFService.generatePDF(
        medicines: _medicines,
        imageFile: imageFile,
        fileName: _pdfNameController.text,
        doctorName:
        _doctorNameController.text.isEmpty ? null : _doctorNameController.text,
        patientName:
        _patientNameController.text.isEmpty ? null : _patientNameController.text,
        extractedText: scanData['extracted_text']?.toString(),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Prescription for ${_patientNameController.text}',
        text: 'Prescription from ${_doctorNameController.text}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      isGeneratingPDF.value = false;
    }
  }
}