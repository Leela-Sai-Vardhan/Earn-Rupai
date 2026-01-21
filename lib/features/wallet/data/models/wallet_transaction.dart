class WalletTransaction {
  final String id;
  final String userId;
  final String? taskId;
  final double amount;
  final String transactionType; // credit, debit, pending, withdrawal
  final String status; // pending, completed, failed
  final String? notes;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    this.taskId,
    required this.amount,
    required this.transactionType,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCredit => transactionType == 'credit';
}
