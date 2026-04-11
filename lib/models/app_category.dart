class AppCategory {
  final String id;
  final String title;
  final String emoji;

  AppCategory({
    required this.id,
    required this.title,
    required this.emoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
    };
  }

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'],
      title: map['title'],
      emoji: map['emoji'],
    );
  }
}
