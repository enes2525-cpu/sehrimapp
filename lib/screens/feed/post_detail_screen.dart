import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sehrimapp/data/models/post_model.dart';
import 'package:sehrimapp/data/models/comment_model.dart';
import 'package:sehrimapp/data/models/user_model.dart';

import 'package:sehrimapp/services/feed_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/services/firestore_service.dart';

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

    final userId = AuthService.currentUserId;
    if (userId == null) {
      _showSnackBar("Giriş yapmalısınız");
      return;
    }

    // Firestore'dan kullanıcı bilgisi çek
    final UserModel? user = await FirestoreService.getUser(userId);
    if (user == null) {
      _showSnackBar("Kullanıcı bilgisi alınamadı");
      return;
    }

    setState(() => _sending = true);

    try {
      await FeedService.addComment(
        postId: widget.post.id,
        userId: user.id,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      _showSnackBar("Hata: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paylaşım")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Kullanıcı bilgisi
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

                  /// İçerik
                  if (widget.post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.post.content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                  /// Fotoğraflar
                  if (widget.post.images.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: widget.post.images.length,
                        itemBuilder: (_, i) {
                          return Image.network(
                            widget.post.images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 60),
                          );
                        },
                      ),
                    ),

                  if (widget.post.images.isEmpty)
                    const SizedBox(height: 16),

                  const Divider(height: 32),

                  /// Yorum başlığı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Yorumlar (${widget.post.commentCount})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Yorum listesi
                  StreamBuilder<List<CommentModel>>(
                    stream: FeedService.getComments(widget.post.id),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final comments = snapshot.data!;
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              "Henüz yorum yok",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (_, i) => _buildCommentCard(comments[i]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
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
                  hintText: "Yorum yaz...",
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _addComment,
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final currentUserId = AuthService.currentUserId;
    final canDelete =
        currentUserId == comment.userId || currentUserId == widget.post.userId;

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundImage: comment.userPhotoUrl != null
            ? NetworkImage(comment.userPhotoUrl!)
            : null,
        child: comment.userPhotoUrl == null
            ? Text(comment.userName[0].toUpperCase())
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
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Text(comment.content),
      trailing: canDelete
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () =>
                  FeedService.deleteComment(comment.id, widget.post.id),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Az önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika";
    if (diff.inHours < 24) return "${diff.inHours} saat";
    if (diff.inDays == 1) return "Dün";
    if (diff.inDays < 7) return "${diff.inDays} gün";

    return DateFormat("dd MMM").format(date);
  }
}
