import 'package:flutter/material.dart';

import '../data/post_repository.dart';
import '../models/app_user.dart';
import '../models/post.dart';
import 'home_screen.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({
    super.key,
    required this.user,
    this.post,
    PostRepository? postRepository,
  }) : _postRepository = postRepository;

  final AppUser user;
  final Post? post;
  final PostRepository? _postRepository;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PostRepository _postRepository;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _postRepository = widget._postRepository ?? PostRepository();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _contentController = TextEditingController(
      text: widget.post?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final post = widget.post;

      if (post == null) {
        await _postRepository.createPost(
          userId: widget.user.id,
          title: title,
          content: content,
        );
      } else {
        await _postRepository.updatePost(
          postId: post.id,
          userId: widget.user.id,
          title: title,
          content: content,
        );
      }

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
          fallback: _isEditing ? '게시글을 수정하지 못했습니다.' : '게시글을 작성하지 못했습니다.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '게시글 수정' : '새 글 작성')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isEditing
                                    ? Icons.edit_note_outlined
                                    : Icons.note_add_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? '게시글 수정' : '새 글 작성',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('post_title_field'),
                            controller: _titleController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: '제목',
                              hintText: '게시글 제목',
                              prefixIcon: Icon(Icons.title),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateTitle,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('post_content_field'),
                            controller: _contentController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: '내용',
                              hintText: '본문을 입력하세요.',
                              alignLabelWithHint: true,
                            ),
                            minLines: 10,
                            maxLines: 18,
                            textInputAction: TextInputAction.newline,
                            validator: _validateContent,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _FormInlineError(
                              key: const Key('post_form_error_text'),
                              message: _errorMessage!,
                            ),
                          ],
                          if (_isSaving) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                          ],
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            key: const Key('save_post_button'),
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? '저장 중...' : '저장'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormInlineError extends StatelessWidget {
  const _FormInlineError({
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

String? _validateTitle(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return '제목을 입력하세요.';
  }
  return null;
}

String? _validateContent(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return '내용을 입력하세요.';
  }
  return null;
}
