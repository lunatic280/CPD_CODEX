import 'package:flutter/material.dart';

import '../data/post_repository.dart';
import '../models/app_user.dart';
import '../models/post.dart';
import '../widgets/post_list_item.dart';
import 'home_screen.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.currentUser,
    PostRepository? postRepository,
  }) : _postRepository = postRepository;

  final int postId;
  final AppUser currentUser;
  final PostRepository? _postRepository;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final PostRepository _postRepository;
  late Future<Post?> _postFuture;
  bool _hasChanged = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _postRepository = widget._postRepository ?? PostRepository();
    _postFuture = _postRepository.findPostById(widget.postId);
  }

  Future<void> _reloadPost() async {
    setState(() {
      _postFuture = _postRepository.findPostById(widget.postId);
      _errorMessage = null;
    });
  }

  Future<void> _openEditForm(Post post) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostFormScreen(
          user: widget.currentUser,
          post: post,
          postRepository: _postRepository,
        ),
      ),
    );

    if (saved == true && mounted) {
      _hasChanged = true;
      await _reloadPost();
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까? 삭제한 글은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            key: const Key('cancel_delete_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm_delete_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deletePost();
    }
  }

  Future<void> _deletePost() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _postRepository.deletePost(
        postId: widget.postId,
        userId: widget.currentUser.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = exceptionMessage(
          error,
          fallback: '게시글을 삭제하지 못했습니다.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _close() {
    Navigator.of(context).pop(_hasChanged);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _close();
        }
      },
      child: FutureBuilder<Post?>(
        future: _postFuture,
        builder: (context, snapshot) {
          final post = snapshot.data;
          final canEdit = post?.userId == widget.currentUser.id;

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _close),
              title: const Text('게시글 상세'),
              actions: [
                if (canEdit) ...[
                  IconButton(
                    key: const Key('edit_post_button'),
                    tooltip: '수정',
                    onPressed: _isDeleting ? null : () => _openEditForm(post!),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    key: const Key('delete_post_button'),
                    tooltip: '삭제',
                    onPressed: _isDeleting ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            body: SafeArea(
              child: _buildBody(context, snapshot),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<Post?> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const _DetailMessage(
        key: Key('post_detail_loading_state'),
        title: '게시글을 불러오는 중입니다.',
        icon: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return _DetailMessage(
        key: const Key('post_detail_error_state'),
        title: '게시글을 불러오지 못했습니다.',
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        message: exceptionMessage(
          snapshot.error!,
          fallback: '잠시 후 다시 시도하세요.',
        ),
        action: OutlinedButton.icon(
          onPressed: _reloadPost,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      );
    }

    final post = snapshot.data;
    if (post == null) {
      return const _DetailMessage(
        key: Key('post_detail_empty_state'),
        title: '게시글을 찾을 수 없습니다.',
        icon: Icon(Icons.article_outlined),
        message: '목록으로 돌아가 다시 확인하세요.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      key: const Key('post_detail_title_text'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.person_outline,
                          label: post.authorName,
                        ),
                        _MetaChip(
                          icon: Icons.schedule,
                          label: formatPostDate(post.createdAt),
                        ),
                        if (post.updatedAt.isAfter(post.createdAt))
                          _MetaChip(
                            icon: Icons.edit_calendar_outlined,
                            label: '수정됨 ${formatPostDate(post.updatedAt)}',
                          ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _DetailInlineError(
                        key: const Key('post_detail_error_text'),
                        message: _errorMessage!,
                      ),
                    ],
                    if (_isDeleting) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 24),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      post.content,
                      key: const Key('post_detail_content_text'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    super.key,
    required this.title,
    this.icon,
    this.message,
    this.action,
  });

  final String title;
  final Widget? icon;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SizedBox(width: 32, height: 32, child: Center(child: icon)),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
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
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxChipWidth =
        (MediaQuery.sizeOf(context).width - 96).clamp(160.0, 360.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInlineError extends StatelessWidget {
  const _DetailInlineError({
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
