class Recipe {
  final String id;
  final String authorId;
  final String title;
  final String? description;
  final List<String> ingredients;
  final List<String> instructions;
  final int? prepTimeMinutes;
  final int? servings;
  final String? category;
  final List<String>? mediaUrls;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.authorId,
    required this.title,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.prepTimeMinutes,
    this.servings,
    this.category,
    this.mediaUrls,
    required this.isHidden,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      servings: json['servings'] as int?,
      category: json['category'] as String?,
      mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : null,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prep_time_minutes': prepTimeMinutes,
      'servings': servings,
      'category': category,
      'media_urls': mediaUrls,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
