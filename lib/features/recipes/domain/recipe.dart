import 'dart:convert';

class InstructionStep {
  final String text;
  final String? imageUrl;

  InstructionStep({required this.text, this.imageUrl});

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      text: json['text'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class Recipe {
  final String id;
  final String authorId;
  final String? authorName;
  final String title;
  final String? description;
  final List<String> ingredients;
  final List<String> instructions;
  final int? prepTimeMinutes;
  final int? servings;
  final String? category;
  final List<String>? mediaUrls;
  final bool isHidden;
  final int editCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.authorId,
    this.authorName,
    required this.title,
    this.description,
    required this.ingredients,
    required this.instructions,
    this.prepTimeMinutes,
    this.servings,
    this.category,
    this.mediaUrls,
    required this.isHidden,
    required this.editCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retorna las instrucciones procesadas. 
  /// Si la instrucción es un JSON (nuevo formato con imagen), la decodifica.
  /// Si es un texto plano (formato antiguo), la trata como un paso sin imagen.
  List<InstructionStep> get parsedInstructions {
    return instructions.map((instructionString) {
      try {
        final decoded = jsonDecode(instructionString);
        if (decoded is Map<String, dynamic> && decoded.containsKey('text')) {
          return InstructionStep.fromJson(decoded);
        }
      } catch (_) {
        // No es JSON, es texto antiguo
      }
      return InstructionStep(text: instructionString);
    }).toList();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del join con profiles para obtener el nombre del autor
    final profile = json['profiles'] as Map<String, dynamic>?;
    final displayName = profile != null ? profile['display_name'] as String? : null;

    return Recipe(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: displayName,
      title: json['title'] as String,
      description: json['description'] as String?,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTimeMinutes: json['prep_time_minutes'] as int?,
      servings: json['servings'] as int?,
      category: json['category'] as String?,
      mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : null,
      isHidden: json['is_hidden'] as bool? ?? false,
      editCount: json['edit_count'] as int? ?? 0,
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
      'edit_count': editCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
