import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';

class WalletBalance {
  const WalletBalance({
    required this.balanceMinor,
    required this.rewardPoints,
    this.currency = 'INR',
    this.isFrozen = false,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        balanceMinor: json['balanceMinor'] as int,
        rewardPoints: json['rewardPoints'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'INR',
        isFrozen: json['isFrozen'] as bool? ?? false,
      );

  final int balanceMinor;
  final int rewardPoints;
  final String currency;
  final bool isFrozen;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.txnType,
    required this.amountMinor,
    required this.source,
    required this.createdAt,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as String,
        txnType: json['txn_type'] as String,
        amountMinor: json['amount_minor'] as int,
        source: json['source'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final String txnType;
  final int amountMinor;
  final String source;
  final String? description;
  final DateTime createdAt;

  bool get isCredit => txnType == 'credit';
}

class WalletRepository {
  WalletRepository(this._client);

  final ApiClient _client;

  Future<WalletBalance> getBalance() async {
    final data = await _client.get('/wallet');
    return WalletBalance.fromJson(data as Map<String, dynamic>);
  }

  Future<PaginatedResult<WalletTransaction>> getTransactions({int page = 1}) async {
    final envelope = await _client.getEnvelope(
      '/wallet/transactions',
      queryParameters: {'page': page, 'limit': 20},
    );
    return PaginatedResult.fromEnvelope(envelope, WalletTransaction.fromJson);
  }
}
