import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/address.dart';
import '../address_controller.dart';

/// Opens the add/edit address form as a bottom sheet. Returns true if the
/// address was saved, so callers (e.g. checkout) can refresh selection.
Future<bool?> showAddressFormSheet(BuildContext context, {Address? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AddressFormSheet(existing: existing),
  );
}

class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet({super.key, this.existing});
  final Address? existing;

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.recipientName);
  late final _phone = TextEditingController(text: widget.existing?.recipientPhone);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _line2 = TextEditingController(text: widget.existing?.line2);
  late final _landmark = TextEditingController(text: widget.existing?.landmark);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _state = TextEditingController(text: widget.existing?.state);
  late final _postalCode = TextEditingController(text: widget.existing?.postalCode);
  String _label = 'home';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _label = widget.existing?.label ?? 'home';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _landmark, _city, _state, _postalCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final address = Address(
      id: widget.existing?.id ?? '',
      label: _label,
      recipientName: _name.text.trim(),
      recipientPhone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postalCode.text.trim(),
    );

    final notifier = ref.read(addressControllerProvider.notifier);
    final error = widget.existing != null
        ? await notifier.update(widget.existing!.id, address)
        : await notifier.add(address);

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.existing != null ? 'Edit address' : 'Add new address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['home', 'work', 'other']
                    .map(
                      (l) => ChoiceChip(
                        label: Text(l[0].toUpperCase() + l.substring(1)),
                        selected: _label == l,
                        onSelected: (_) => setState(() => _label = l),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _name,
                label: 'Recipient name',
                validator: Validators.fullName,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.isPhone(v ?? '') ? null : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _line1,
                label: 'Address line 1',
                validator: (v) => Validators.required(v, label: 'Address'),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _line2, label: 'Address line 2 (optional)'),
              const SizedBox(height: 12),
              AppTextField(controller: _landmark, label: 'Landmark (optional)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _city,
                      label: 'City',
                      validator: (v) => Validators.required(v, label: 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _state,
                      label: 'State',
                      validator: (v) => Validators.required(v, label: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _postalCode,
                label: 'Postal code',
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, label: 'Postal code'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Save address', isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
