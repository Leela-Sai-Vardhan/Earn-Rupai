class TaskModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String instructions;
  final double rewardAmount;
  final String externalUrl;
  final String? companyInfo;
  final bool isActive;
  final int maxCompletions;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.instructions,
    required this.rewardAmount,
    required this.externalUrl,
    this.companyInfo,
    required this.isActive,
    required this.maxCompletions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String,
      rewardAmount: (json['reward_amount'] as num).toDouble(),
      externalUrl: json['external_url'] as String,
      companyInfo: json['company_info'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      maxCompletions: json['max_completions'] as int? ?? -1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'instructions': instructions,
      'reward_amount': rewardAmount,
      'external_url': externalUrl,
      'company_info': companyInfo,
      'is_active': isActive,
      'max_completions': maxCompletions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Category display names
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'survey':
        return 'Survey';
      case 'video':
        return 'Video';
      case 'app_install':
        return 'App Install';
      case 'social_media':
        return 'Social Media';
      case 'review':
        return 'Review';
      case 'signup':
        return 'Sign Up';
      default:
        return category;
    }
  }

  // Category colors
  static int getCategoryColor(String category) {
    switch (category) {
      case 'survey':
        return 0xFF4CAF50; // Green
      case 'video':
        return 0xFFE91E63; // Pink
      case 'app_install':
        return 0xFF2196F3; // Blue
      case 'social_media':
        return 0xFF9C27B0; // Purple
      case 'review':
        return 0xFFFF9800; // Orange
      case 'signup':
        return 0xFF00BCD4; // Cyan
      default:
        return 0xFF757575; // Grey
    }
  }
}
