import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cpd_test_app/data/post_repository.dart';
import 'package:cpd_test_app/models/app_user.dart';
import 'package:cpd_test_app/models/post.dart';
import 'package:cpd_test_app/screens/home_screen.dart';

void main() {
  testWidgets('게시글 작성 후 목록을 갱신한다', (tester) async {
    final repository = _FakePostRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: _currentUser,
          onSignOut: () async {},
          postRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posts_empty_state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('new_post_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('post_title_field')), '첫 글');
    await tester.enterText(
      find.byKey(const Key('post_content_field')),
      '게시글 내용입니다.',
    );
    await tester.tap(find.byKey(const Key('save_post_button')));
    await tester.pumpAndSettle();

    expect(find.text('첫 글'), findsOneWidget);
    expect(repository.posts.length, 1);
  });

  testWidgets('내 게시글 상세에서 삭제 확인 후 목록을 갱신한다', (tester) async {
    final repository = _FakePostRepository(
      initialPosts: [
        _post(id: 1, title: '삭제할 글', content: '삭제 대상입니다.'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: _currentUser,
          onSignOut: () async {},
          postRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제할 글'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_post_button')));
    await tester.pumpAndSettle();

    expect(find.text('이 게시글을 삭제하시겠습니까? 삭제한 글은 되돌릴 수 없습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_delete_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('posts_empty_state')), findsOneWidget);
    expect(repository.posts, isEmpty);
  });

  testWidgets('게시글 폼에서 제목과 내용 공백을 검증한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: _currentUser,
          onSignOut: () async {},
          postRepository: _FakePostRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new_post_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_post_button')));
    await tester.pump();

    expect(find.text('제목을 입력하세요.'), findsOneWidget);
    expect(find.text('내용을 입력하세요.'), findsOneWidget);
  });
}

final _currentUser = AppUser(
  id: 1,
  email: 'student@example.com',
  displayName: '학생',
  createdAt: DateTime.utc(2026, 5, 8),
);

Post _post({
  required int id,
  required String title,
  required String content,
}) {
  return Post(
    id: id,
    userId: _currentUser.id,
    authorName: _currentUser.displayName,
    title: title,
    content: content,
    createdAt: DateTime.utc(2026, 5, 8, 10),
    updatedAt: DateTime.utc(2026, 5, 8, 10),
  );
}

class _FakePostRepository extends PostRepository {
  _FakePostRepository({List<Post>? initialPosts})
      : posts = List<Post>.from(initialPosts ?? const []);

  final List<Post> posts;
  int _nextId = 1;

  @override
  Future<List<Post>> fetchPosts() async {
    return List<Post>.from(posts);
  }

  @override
  Future<Post?> findPostById(int id) async {
    for (final post in posts) {
      if (post.id == id) {
        return post;
      }
    }
    return null;
  }

  @override
  Future<Post> createPost({
    required int userId,
    required String title,
    required String content,
  }) async {
    final post = Post(
      id: _nextId++,
      userId: userId,
      authorName: _currentUser.displayName,
      title: title,
      content: content,
      createdAt: DateTime.utc(2026, 5, 8, 11),
      updatedAt: DateTime.utc(2026, 5, 8, 11),
    );
    posts.insert(0, post);
    return post;
  }

  @override
  Future<Post> updatePost({
    required int postId,
    required int userId,
    required String title,
    required String content,
  }) async {
    final index = posts.indexWhere((post) => post.id == postId);
    final updatedPost = Post(
      id: postId,
      userId: userId,
      authorName: _currentUser.displayName,
      title: title,
      content: content,
      createdAt: posts[index].createdAt,
      updatedAt: DateTime.utc(2026, 5, 8, 12),
    );
    posts[index] = updatedPost;
    return updatedPost;
  }

  @override
  Future<void> deletePost({
    required int postId,
    required int userId,
  }) async {
    posts.removeWhere((post) => post.id == postId && post.userId == userId);
  }
}
