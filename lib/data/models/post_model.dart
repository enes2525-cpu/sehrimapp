import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy; // Beğenen kullanıcı ID'leri
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    List<String>? images,
    this.likeCount = 0,
    this.commentCount = 0,
    List<String>? likedBy,
    required this.createdAt,
  })  : images = images ?? [],
        likedBy = likedBy ?? [];

  // Firestore'dan veri çekme
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      likedBy: data['likedBy'] != null ? List<String>.from(data['likedBy']) : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a kaydetme
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'images': images,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Beğeni ekle/çıkar
  PostModel toggleLike(String userId) {
    final newLikedBy = List<String>.from(likedBy);
    final newLikeCount = likeCount;

    if (newLikedBy.contains(userId)) {
      newLikedBy.remove(userId);
      return PostModel(
        id: id,
        userId: this.userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        images: images,
        likeCount: newLikeCount - 1,
        commentCount: commentCount,
        likedBy: newLikedBy,
        createdAt: createdAt,
      );
    } else {
      newLikedBy.add(userId);
      return PostModel(
        id: id,
        userId: this.userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        images: images,
        likeCount: newLikeCount + 1,
        commentCount: commentCount,
        likedBy: newLikedBy,
        createdAt: createdAt,
      );
    }
  }

  // Kullanıcı beğenmiş mi?
  bool isLikedBy(String userId) => likedBy.contains(userId);
}
