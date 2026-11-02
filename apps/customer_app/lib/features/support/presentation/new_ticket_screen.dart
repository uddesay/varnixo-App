import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/primary_button.dart';
import 'support_providers.dart';
import 'support_tickets_controller.dart';

const List<(String, String)> _categories = [
  ('order', 'Order issue'),
  ('payment', 'Payment issue'),
  ('return', 'Returns & refunds'),
  ('account', 'Account'),
  ('general', 'Something else'),
];

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = _categories.first.$1;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final ticket = await ref.read(supportRepositoryProvider).createTicket(
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
            category: _category,
          );
      ref.read(supportTicketsControllerProvider.notifier).refresh();
      if (mounted) context.pushReplacement(RoutePaths.ticketDetailPath(ticket.id));
    } on ApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New support request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                maxLength: 200,
                validator: (value) =>
                    (value == null || value.trim().length < 3) ? 'Enter a short subject' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'How can we help?',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 4000,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Tell us what happened' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 8),
              PrimaryButton(label: 'Submit request', isLoading: _isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
