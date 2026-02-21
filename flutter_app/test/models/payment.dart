/// Test-only payment models used by test fixtures.

enum PaymentMethod {
  monCashManual,
  monCashAutomated,
  natCashManual,
  natCashAutomated,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class Payment {
  final String id;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String userId;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.userId,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });
}
