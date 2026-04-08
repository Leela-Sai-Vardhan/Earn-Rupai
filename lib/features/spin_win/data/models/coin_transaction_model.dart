class CoinTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String transactionType; // 'spin_earn', 'withdrawal'
  final String status; // 'completed', 'pending', 'rewarded'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoinTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) {
    return CoinTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'transaction_type': transactionType,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
