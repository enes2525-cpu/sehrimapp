import 'package:flutter/material.dart';
import 'package:sehrimapp/services/follow_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:intl/intl.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int initialTab; // 0: Takipçiler, 1: Takip Edilenler

  const FollowListScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowersTab(userId: widget.userId),
          _FollowingTab(userId: widget.userId),
        ],
      ),
    );
  }
}

// Takipçiler Tab
class _FollowersTab extends StatelessWidget {
  final String userId;

  const _FollowersTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FollowService.getFollowers(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz takipçi yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final followers = snapshot.data!;
        return ListView.separated(
          itemCount: followers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final follower = followers[index];
            return _UserTile(user: follower);
          },
        );
      },
    );
  }
}

// Takip Edilenler Tab
class _FollowingTab extends StatelessWidget {
  final String userId;

  const _FollowingTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FollowService.getFollowing(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz kimseyi takip etmiyor',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final following = snapshot.data!;
        return ListView.separated(
          itemCount: following.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = following[index];
            return _UserTile(user: user, showUnfollow: true);
          },
        );
      },
    );
  }
}

// Kullanıcı Tile Widget
class _UserTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool showUnfollow;

  const _UserTile({
    required this.user,
    this.showUnfollow = false,
  });

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _isFollowing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return;

    final isFollowing = await FollowService.isFollowing(
      followerId: currentUserId,
      followingId: widget.user['id'],
    );

    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null) return;

    setState(() => _loading = true);

    try {
      if (_isFollowing) {
        await FollowService.unfollowUser(
          followerId: currentUserId,
          followingId: widget.user['id'],
        );
      } else {
        await FollowService.followUser(
          followerId: currentUserId,
          followingId: widget.user['id'],
          followerName: 'Kullanıcı', // TODO: Get actual name
        );
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUserId;
    final isCurrentUser = currentUserId == widget.user['id'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.user['photoUrl'] != null
            ? NetworkImage(widget.user['photoUrl'])
            : null,
        child: widget.user['photoUrl'] == null
            ? Text(widget.user['name'][0].toUpperCase())
            : null,
      ),
      title: Text(widget.user['name']),
      subtitle: widget.user['followedAt'] != null
          ? Text(
              DateFormat('dd MMM yyyy').format(widget.user['followedAt']),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : null,
      trailing: isCurrentUser
          ? null
          : _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  onPressed: _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey.shade100 : Colors.blue,
                    foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  ),
                  child: Text(_isFollowing ? 'Takiptesin' : 'Takip Et'),
                ),
      onTap: () {
        // TODO: Navigate to user profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user['name']} profili')),
        );
      },
    );
  }
}
