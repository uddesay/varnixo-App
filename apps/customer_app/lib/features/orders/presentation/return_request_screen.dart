import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'order_providers.dart';

const List<String> _reasons = [
  'Item damaged or defective',
  'Wrong item delivered',
  'Item not as described',
  'Size or fit issue',
  'No longer needed',
  'Other',
];

class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({required this.orderItemId, super.key});

  final String orderItemId;

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String _requestType = 'return';
  String _reason = _reasons.first;
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(orderRepositoryProvider).createReturnRequest(
            orderItemId: widget.orderItemId,
            requestType: _requestType,
            reason: _reason,
            description: _descriptionController.text.trim(),
            quantity: _quantity,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Return request submitted')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return or Exchange')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Request type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'return', label: Text('Return')),
              ButtonSegment(value: 'exchange', label: Text('Exchange')),
            ],
            selected: {_requestType},
            onSelectionChanged: (selection) => setState(() => _requestType = selection.first),
          ),
          const SizedBox(height: 20),
          Text('Reason', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._reasons.map(
            (r) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: r,
              groupValue: _reason,
              title: Text(r),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Quantity', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
              ),
              Text('$_quantity'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity += 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _descriptionController,
            label: 'Additional details (optional)',
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Submit request', isLoading: _isSubmitting, onPressed: _submit),
        ],
      ),
    );
  }
}
