import 'package:flutter/material.dart';

import '../data/post_repository.dart';
import '../models/app_user.dart';
import '../models/post.dart';
import '../widgets/post_list_item.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    PostRepository? postRepository,
  }) : _postRepository = postRepository;

  final AppUser user;
  final Future<void> Function() onSignOut;
  final PostRepository? _postRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PostRepository _postRepository;
  late Future<List<Post>> _postsFuture;
  bool _isSigningOut = false;
  String? _signOutErrorMessage;

  @override
  void initState() {
    super.initState();
    _postRepository = widget._postRepository ?? PostRepository();
    _postsFuture = _postRepository.fetchPosts();
  }

  Future<void> _reloadPosts() async {
    setState(() {
      _postsFuture = _postRepository.fetchPosts();
    });
  }

  Future<void> _openNewPostForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostFormScreen(
          user: widget.user,
          postRepository: _postRepository,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _reloadPosts();
    }
  }

  Future<void> _openPostDetail(Post post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          currentUser: widget.user,
          postRepository: _postRepository,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _reloadPosts();
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
      _signOutErrorMessage = null;
    });

    try {
      await widget.onSignOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _signOutErrorMessage = exceptionMessage(
            error,
            fallback: '로그아웃 중 문제가 발생했습니다.',
          ));
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayInitial = widget.user.displayName.trim().isEmpty
        ? '?'
        : widget.user.displayName.characters.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        actions: [
          TextButton.icon(
            key: const Key('logout_button'),
            onPressed: _isSigningOut ? null : _signOut,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(_isSigningOut ? '처리 중...' : '로그아웃'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_post_button'),
        onPressed: _openNewPostForm,
        icon: const Icon(Icons.add),
        label: const Text('새 글'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadPosts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
            children: [
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        child: Text(displayInitial),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.user.displayName}님, 환영합니다.',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              key: const Key('home_user_email_text'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_signOutErrorMessage != null) ...[
                const SizedBox(height: 12),
                _InlineErrorMessage(
                  key: const Key('home_sign_out_error_text'),
                  message: _signOutErrorMessage!,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    '게시글 목록',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('reload_posts_button'),
                    tooltip: '새로고침',
                    onPressed: _reloadPosts,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Post>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _PostStateMessage(
                      key: Key('posts_loading_state'),
                      icon: CircularProgressIndicator(),
                      title: '게시글을 불러오는 중입니다.',
                    );
                  }

                  if (snapshot.hasError) {
                    return _PostStateMessage(
                      key: const Key('posts_error_state'),
                      icon: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: '게시글을 불러오지 못했습니다.',
                      message: exceptionMessage(
                        snapshot.error!,
                        fallback: '잠시 후 다시 시도하세요.',
                      ),
                      action: OutlinedButton.icon(
                        onPressed: _reloadPosts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    );
                  }

                  final posts = snapshot.data ?? const <Post>[];
                  if (posts.isEmpty) {
                    return const _PostStateMessage(
                      key: Key('posts_empty_state'),
                      icon: Icon(Icons.article_outlined),
                      title: '아직 작성된 게시글이 없습니다.',
                      message: '새 글 버튼을 눌러 첫 게시글을 작성해 보세요.',
                    );
                  }

                  return Column(
                    key: const Key('post_list'),
                    children: [
                      for (final post in posts)
                        PostListItem(
                          post: post,
                          onTap: () => _openPostDetail(post),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostStateMessage extends StatelessWidget {
  const _PostStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final Widget icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(width: 32, height: 32, child: Center(child: icon)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  const _InlineErrorMessage({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

String exceptionMessage(Object error, {required String fallback}) {
  try {
    final dynamic dynamicError = error;
    final message = dynamicError.message;
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  } catch (_) {
    // message 필드가 없는 예외는 기본 문구를 사용한다.
  }
  return fallback;
}
