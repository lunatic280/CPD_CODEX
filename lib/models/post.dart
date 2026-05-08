class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String authorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Post.fromMap(Map<String, Object?> map) {
    return Post(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      authorName: map['author_name'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
