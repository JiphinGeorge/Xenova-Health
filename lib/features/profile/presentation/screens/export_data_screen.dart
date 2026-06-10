import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reports/data/services/report_export_service.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  String _selectedFormat = 'PDF';
  String _selectedDataType = 'Full Health Report';
  bool _isExporting = false;

  final List<String> _formats = ['PDF', 'CSV'];
  final List<String> _dataTypes = [
    'Full Health Report',
    'Weight History',
    'Nutrition Logs',
    'Fasting Logs',
  ];

  Future<void> _handleExport() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() => _isExporting = true);
    
    try {
      final exportService = ref.read(reportExportServiceProvider);
      await exportService.exportAndShare(user.uid, _selectedDataType, _selectedFormat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Data Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            ..._dataTypes.map((type) => RadioListTile<String>(
                  title: Text(type),
                  value: type,
                  groupValue: _selectedDataType,
                  onChanged: (value) {
                    setState(() => _selectedDataType = value!);
                    if (value == 'Full Health Report') {
                      setState(() => _selectedFormat = 'PDF');
                    }
                  },
                )),
            const SizedBox(height: AppDimensions.spacingLg),
            
            Text(
              'Select Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            ..._formats.map((format) => RadioListTile<String>(
                  title: Text(format),
                  value: format,
                  groupValue: _selectedFormat,
                  onChanged: _selectedDataType == 'Full Health Report' && format == 'CSV' 
                    ? null 
                    : (value) {
                        setState(() => _selectedFormat = value!);
                      },
                )),
            const Spacer(),
            
            FilledButton.icon(
              onPressed: _isExporting ? null : _handleExport,
              icon: _isExporting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Generating...' : 'Export $_selectedFormat'),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
          ],
        ),
      ),
    );
  }
}
