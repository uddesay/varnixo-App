import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/wallet_repository.dart';

final Provider<WalletRepository> walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

final FutureProvider<WalletBalance> walletBalanceProvider =
    FutureProvider<WalletBalance>((ref) => ref.watch(walletRepositoryProvider).getBalance());
