import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_view.dart';
import '../data/wallet_repository.dart';
import 'wallet_providers.dart';

final FutureProvider<List<WalletTransaction>> _transactionsProvider =
    FutureProvider<List<WalletTransaction>>((ref) async {
  final result = await ref.watch(walletRepositoryProvider).getTransactions();
  return result.items;
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(_transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(_transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            balanceAsync.when(
              data: (balance) => _BalanceCard(balance: balance),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (error, stack) => ErrorView(error: error),
            ),
            const SizedBox(height: 24),
            Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No transactions yet')),
                  );
                }
                return Column(
                  children: transactions.map((t) => _TransactionTile(transaction: t)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorView(error: error),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance.balanceMinor),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 6),
              Text('${balance.rewardPoints} reward points', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.isCredit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.12),
        child: Icon(
          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: isCredit ? AppColors.success : AppColors.error,
          size: 18,
        ),
      ),
      title: Text(transaction.description ?? transaction.source.replaceAll('_', ' ')),
      subtitle: Text('${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}'),
      trailing: Text(
        '${isCredit ? '+' : '-'}${CurrencyFormatter.format(transaction.amountMinor)}',
        style: TextStyle(
          color: isCredit ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
