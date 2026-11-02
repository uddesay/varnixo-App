import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/address.dart';
import 'address_controller.dart';
import 'widgets/address_form_sheet.dart';

/// Standalone address book (Profile → Addresses). Checkout has its own
/// inline picker but reuses [showAddressFormSheet] for adding new ones.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddressFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: _body(context, ref, state),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AddressListState state) {
    if (state.isLoading && state.addresses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.addresses.isEmpty) {
      return ErrorView(error: state.error!, onRetry: () => ref.read(addressControllerProvider.notifier).refresh());
    }
    if (state.addresses.isEmpty) {
      return EmptyStateView(
        icon: Icons.location_on_outlined,
        title: 'No saved addresses',
        message: 'Add a delivery address to speed up checkout.',
        actionLabel: 'Add address',
        onAction: () => showAddressFormSheet(context),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.addresses.length,
      itemBuilder: (context, index) {
        final Address address = state.addresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(address.label.toUpperCase())),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      const Chip(label: Text('DEFAULT')),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(address.recipientPhone),
                Text(address.formatted),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!address.isDefault)
                      TextButton(
                        onPressed: () =>
                            ref.read(addressControllerProvider.notifier).setDefault(address.id),
                        child: const Text('Set as default'),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => showAddressFormSheet(context, existing: address),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () =>
                          ref.read(addressControllerProvider.notifier).remove(address.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
