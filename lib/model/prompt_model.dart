class Prompt {
  String? id; // uuid stored as string
  String? title;
  String? prompt;
  String? ownerId;
  DateTime? createdAt;

  Prompt({
    this.id,
    this.title,
    this.prompt,
    this.ownerId,
    this.createdAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id']?.toString(),
      title: json['title'] as String?,
      prompt: json['prompt'] as String?,
      ownerId: json['owner_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'prompt': prompt,
        'owner_id': ownerId,
        'created_at': createdAt?.toIso8601String(),
      };
}
