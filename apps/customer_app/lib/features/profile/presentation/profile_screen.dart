import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/router/route_paths.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This will permanently delete your account and personal data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(apiClientProvider)
          .delete('/users/account', data: {'confirmation': 'DELETE'});
      await ref.read(authControllerProvider.notifier).logout();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not delete account')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null
                    ? Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      user?.email ?? user?.phone ?? '',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () => context.push(RoutePaths.orders),
          ),
          _MenuTile(
            icon: Icons.location_on_outlined,
            label: 'My Addresses',
            onTap: () => context.push(RoutePaths.addresses),
          ),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            onTap: () => context.push(RoutePaths.wallet),
          ),
          _MenuTile(
            icon: Icons.favorite_border_rounded,
            label: 'Wishlist',
            onTap: () => context.push(RoutePaths.wishlist),
          ),
          _MenuTile(
            icon: Icons.support_agent_outlined,
            label: 'Help & Support',
            onTap: () => context.push(RoutePaths.support),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
              },
            ),
          ),
          const Divider(height: 32),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Log out',
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          _MenuTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete account',
            color: Colors.red,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => Center(
              child: Text(
                snapshot.hasData ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})' : '',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
