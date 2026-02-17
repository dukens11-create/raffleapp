class PaymentMethod {
  final String method;
  final String displayName;
  final bool isAutomated;
  final bool isActive;

  PaymentMethod({
    required this.method,
    required this.displayName,
    required this.isAutomated,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      method: json['method'] ?? '',
      displayName: json['display_name'] ?? '',
      isAutomated: json['is_automated'] ?? false,
      isActive: json['is_active'] ?? false,
    );
  }
}

class ManualInstructions {
  final String method;
  final String walletNumber;
  final List<String> instructions;

  ManualInstructions({
    required this.method,
    required this.walletNumber,
    required this.instructions,
  });

  factory ManualInstructions.fromJson(Map<String, dynamic> json) {
    return ManualInstructions(
      method: json['method'] ?? '',
      walletNumber: json['wallet_number'] ?? '',
      instructions: (json['instructions'] as List?)?.cast<String>() ?? [],
    );
  }
}
