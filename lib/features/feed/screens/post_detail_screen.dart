import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/post_model.dart';
import 'package:sehrimapp/data/models/comment_model.dart';
import 'package:sehrimapp/services/feed_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = AuthService.currentUser;
    if (user == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _sending = true);

    try {
      await FeedService.addComment(
        postId: widget.post.id,
        userId: user.uid,
        userName: user.displayName ?? 'Anonim',
        userPhotoUrl: user.photoURL,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showSnackBar('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşım'),
      ),
      body: Column(
        children: [
          // Post içeriği
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı bilgisi
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: widget.post.userPhotoUrl != null
                          ? NetworkImage(widget.post.userPhotoUrl!)
                          : null,
                      child: widget.post.userPhotoUrl == null
                          ? Text(widget.post.userName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(
                      widget.post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_formatDate(widget.post.createdAt)),
                  ),

                  // İçerik
                  if (widget.post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.post.content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                  // Fotoğraflar
                  if (widget.post.images.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: widget.post.images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.post.images[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),

                  const Divider(height: 32),

                  // Yorumlar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Yorumlar (${widget.post.commentCount})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<List<CommentModel>>(
                    stream: FeedService.getComments(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Henüz yorum yok',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }

                      final comments = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentCard(comments[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Yorum giriş alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade700,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _addComment,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final currentUserId = AuthService.currentUserId;
    final canDelete = currentUserId == comment.userId || 
                      currentUserId == widget.post.userId;

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundImage: comment.userPhotoUrl != null
            ? NetworkImage(comment.userPhotoUrl!)
            : null,
        child: comment.userPhotoUrl == null
            ? Text(
                comment.userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(
            comment.userName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDate(comment.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      subtitle: Text(comment.content),
      trailing: canDelete
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Yorumu Sil'),
                    content: const Text('Bu yorumu silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FeedService.deleteComment(comment.id, widget.post.id);
                }
              },
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}d';
    if (diff.inHours < 24) return '${diff.inHours}s';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return DateFormat('dd MMM').format(date);
  }
}
