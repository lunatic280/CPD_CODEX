import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cpd_test_app/data/app_database.dart';
import 'package:cpd_test_app/data/auth_repository.dart';
import 'package:cpd_test_app/data/post_repository.dart';

void main() {
  late AppDatabase database;
  late AuthRepository authRepository;
  late PostRepository postRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await AppDatabase.openInMemoryForTest();
    authRepository = AuthRepository(database: database);
    postRepository = PostRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createUser({
    String email = 'student@example.com',
    String displayName = '학생',
  }) async {
    final user = await authRepository.signUp(
      email: email,
      displayName: displayName,
      password: 'password123',
    );
    return user.id;
  }

  test('게시글을 작성하고 상세 조회할 수 있다', () async {
    final userId = await createUser(displayName: '작성자');

    final post = await postRepository.createPost(
      userId: userId,
      title: ' 첫 글 ',
      content: ' 게시글 내용 ',
    );
    final foundPost = await postRepository.findPostById(post.id);

    expect(post.id, greaterThan(0));
    expect(post.userId, userId);
    expect(post.authorName, '작성자');
    expect(post.title, '첫 글');
    expect(post.content, '게시글 내용');
    expect(foundPost?.id, post.id);
  });

  test('게시글 목록은 최신순으로 조회된다', () async {
    final userId = await createUser();

    final firstPost = await postRepository.createPost(
      userId: userId,
      title: '첫 글',
      content: '첫 내용',
    );
    final secondPost = await postRepository.createPost(
      userId: userId,
      title: '두 번째 글',
      content: '두 번째 내용',
    );

    final posts = await postRepository.fetchPosts();

    expect(posts.map((post) => post.id), [secondPost.id, firstPost.id]);
  });

  test('작성자만 게시글을 수정할 수 있다', () async {
    final authorId = await createUser(
      email: 'author@example.com',
      displayName: '작성자',
    );
    final otherUserId = await createUser(
      email: 'other@example.com',
      displayName: '다른 학생',
    );
    final post = await postRepository.createPost(
      userId: authorId,
      title: '제목',
      content: '내용',
    );

    expect(
      () => postRepository.updatePost(
        postId: post.id,
        userId: otherUserId,
        title: '수정 제목',
        content: '수정 내용',
      ),
      throwsA(isA<PostException>()),
    );

    final updatedPost = await postRepository.updatePost(
      postId: post.id,
      userId: authorId,
      title: '수정 제목',
      content: '수정 내용',
    );

    expect(updatedPost.title, '수정 제목');
    expect(updatedPost.content, '수정 내용');
    expect(updatedPost.updatedAt.isBefore(updatedPost.createdAt), isFalse);
  });

  test('작성자만 게시글을 삭제할 수 있다', () async {
    final authorId = await createUser(
      email: 'author@example.com',
      displayName: '작성자',
    );
    final otherUserId = await createUser(
      email: 'other@example.com',
      displayName: '다른 학생',
    );
    final post = await postRepository.createPost(
      userId: authorId,
      title: '제목',
      content: '내용',
    );

    expect(
      () => postRepository.deletePost(
        postId: post.id,
        userId: otherUserId,
      ),
      throwsA(isA<PostException>()),
    );

    await postRepository.deletePost(postId: post.id, userId: authorId);

    expect(await postRepository.findPostById(post.id), isNull);
  });

  test('제목과 본문은 공백만 입력할 수 없다', () async {
    final userId = await createUser();

    expect(
      () => postRepository.createPost(
        userId: userId,
        title: ' ',
        content: '내용',
      ),
      throwsA(isA<PostException>()),
    );
    expect(
      () => postRepository.createPost(
        userId: userId,
        title: '제목',
        content: ' ',
      ),
      throwsA(isA<PostException>()),
    );
  });
}
