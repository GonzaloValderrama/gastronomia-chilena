class Comment {
  final String id;
  final String recipeId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  
  // Datos unidos desde la tabla profiles
  final String authorName;
  final String? authorAvatarUrl;

  Comment({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del join con profiles
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile?['display_name'] as String? ?? 'Usuario Chileno';
    final avatarUrl = profile?['avatar_url'] as String?;

    return Comment(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: displayName,
      authorAvatarUrl: avatarUrl,
    );
  }
}
