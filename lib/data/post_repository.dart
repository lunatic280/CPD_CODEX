import 'package:sqflite/sqflite.dart';

import '../models/post.dart';
import 'app_database.dart';

class PostException implements Exception {
  const PostException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PostRepository {
  PostRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Post>> fetchPosts() async {
    final db = await _database.database;
    final rows = await _queryPosts(db);
    return rows.map(Post.fromMap).toList();
  }

  Future<Post?> findPostById(int id) async {
    final db = await _database.database;
    final rows = await _queryPosts(
      db,
      where: 'posts.id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return Post.fromMap(rows.first);
  }

  Future<Post> createPost({
    required int userId,
    required String title,
    required String content,
  }) async {
    final trimmedTitle = _validateTitle(title);
    final trimmedContent = _validateContent(content);
    final db = await _database.database;
    await _requireUserExists(db, userId);

    final now = DateTime.now().toUtc();
    final postId = await db.insert('posts', {
      'user_id': userId,
      'title': trimmedTitle,
      'content': trimmedContent,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final post = await findPostById(postId);
    if (post == null) {
      throw const PostException('게시글을 불러오지 못했습니다.');
    }
    return post;
  }

  Future<Post> updatePost({
    required int postId,
    required int userId,
    required String title,
    required String content,
  }) async {
    final trimmedTitle = _validateTitle(title);
    final trimmedContent = _validateContent(content);
    final db = await _database.database;
    await _requireAuthor(db, postId: postId, userId: userId);

    await db.update(
      'posts',
      {
        'title': trimmedTitle,
        'content': trimmedContent,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    final post = await findPostById(postId);
    if (post == null) {
      throw const PostException('게시글을 불러오지 못했습니다.');
    }
    return post;
  }

  Future<void> deletePost({
    required int postId,
    required int userId,
  }) async {
    final db = await _database.database;
    await _requireAuthor(db, postId: postId, userId: userId);

    await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  Future<List<Map<String, Object?>>> _queryPosts(
    DatabaseExecutor db, {
    String? where,
    List<Object?>? whereArgs,
    int? limit,
  }) {
    return db.query(
      'posts INNER JOIN users ON users.id = posts.user_id',
      columns: [
        'posts.id',
        'posts.user_id',
        'users.display_name AS author_name',
        'posts.title',
        'posts.content',
        'posts.created_at',
        'posts.updated_at',
      ],
      where: where,
      whereArgs: whereArgs,
      orderBy: 'posts.created_at DESC, posts.id DESC',
      limit: limit,
    );
  }

  Future<void> _requireUserExists(DatabaseExecutor db, int userId) async {
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const PostException('사용자 정보를 찾을 수 없습니다.');
    }
  }

  Future<void> _requireAuthor(
    DatabaseExecutor db, {
    required int postId,
    required int userId,
  }) async {
    final rows = await db.query(
      'posts',
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const PostException('게시글을 찾을 수 없습니다.');
    }
    if (rows.first['user_id'] != userId) {
      throw const PostException('작성자만 수정하거나 삭제할 수 있습니다.');
    }
  }

  String _validateTitle(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const PostException('제목을 입력하세요.');
    }
    return trimmedTitle;
  }

  String _validateContent(String content) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw const PostException('본문을 입력하세요.');
    }
    return trimmedContent;
  }
}
