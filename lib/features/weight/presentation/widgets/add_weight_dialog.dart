import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/weight_entry_model.dart';
import '../controllers/weight_controller.dart';

/// A dialog to log or edit a weight entry.
class AddWeightDialog extends ConsumerStatefulWidget {
  const AddWeightDialog({super.key, this.existingEntry});

  final WeightEntryModel? existingEntry;

  @override
  ConsumerState<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<AddWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;

    if (widget.existingEntry != null) {
      _weightController = TextEditingController(
        text: widget.existingEntry!.weight.toString(),
      );
      _noteController.text = widget.existingEntry!.note ?? '';
      _selectedDate = widget.existingEntry!.date;
    } else {
      _weightController = TextEditingController(
        text: user?.currentWeightKg?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    try {
      if (widget.existingEntry != null) {
        final updated = widget.existingEntry!.copyWith(
          weight: weight,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          date: _selectedDate,
        );
        await ref.read(weightControllerProvider.notifier).updateEntry(updated);
      } else {
        await ref
            .read(weightControllerProvider.notifier)
            .addEntry(
              weight: weight,
              note: _noteController.text.trim(),
              date: _selectedDate,
            );
      }
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(weightControllerProvider).isLoading;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.existingEntry != null ? "Edit" : "Log"} Weight',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(dateStr),
                      onPressed: _selectDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingMd),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Morning after fast',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              ElevatedButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${widget.existingEntry != null ? "Update" : "Save"} Entry',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
