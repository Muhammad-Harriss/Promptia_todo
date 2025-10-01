class Prompt {
  String? id; 
  String? title;
  String? prompt;
  String? ownerId;
  DateTime? createdAt;
  String status; 
  Prompt({
    this.id,
    this.title,
    this.prompt,
    this.ownerId,
    this.createdAt,
    required this.status,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id']?.toString(),
      title: json['title'] as String?,
      prompt: json['prompt'] as String?,
      ownerId: json['owner_id'] as String?,
      status: json['status']?.toString() ?? 'pending', 
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
        'status': status, 
      };
}
