import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user_streak.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  UserStreak? _streak;
  bool _isLoading = true;
  String? _error;

  // Sample leaderboard data (placeholder - API doesn't have leaderboard endpoint yet)
  static const List<Map<String, dynamic>> leaderboard = [
    {'name': 'Sarah M.', 'streak': 45, 'isCurrentUser': false},
    {'name': 'Alex K.', 'streak': 32, 'isCurrentUser': false},
    {'name': 'Jordan L.', 'streak': 28, 'isCurrentUser': false},
    {'name': 'Taylor W.', 'streak': 21, 'isCurrentUser': false},
    {'name': 'Morgan P.', 'streak': 18, 'isCurrentUser': false},
    {'name': 'Riley S.', 'streak': 14, 'isCurrentUser': false},
    {'name': 'Quinn D.', 'streak': 9, 'isCurrentUser': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final userId = AuthService.userId;
    if (userId == null) {
      setState(() {
        _error = 'Not signed in';
        _isLoading = false;
      });
      return;
    }

    try {
      final streak = await ApiService.getStreak(userId);
      setState(() {
        _streak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getLeaderboardWithUser() {
    final currentStreak = _streak?.currentStreak ?? 0;
    final allEntries = [
      ...leaderboard,
      {'name': 'You', 'streak': currentStreak, 'isCurrentUser': true},
    ];
    allEntries.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));
    return allEntries;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Streak")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentStreak = _streak?.currentStreak ?? 0;
    final longestStreak = _streak?.longestStreak ?? 0;
    final leaderboardWithUser = _getLeaderboardWithUser();

    return Scaffold(
      appBar: AppBar(title: const Text("Streak")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          children: [
            // Streak Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentStreak',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Day Streak',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Longest: $longestStreak days',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Leaderboard Section
            Row(
              children: [
                const Icon(Icons.leaderboard, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboardWithUser.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final entry = leaderboardWithUser[index];
                final isCurrentUser = entry['isCurrentUser'] as bool;
                final rank = index + 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                  decoration: isCurrentUser
                      ? BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 32,
                        child: Text(
                          rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                          style: TextStyle(
                            fontSize: rank <= 3 ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCurrentUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                        child: Text(
                          entry['name'].toString().substring(0, 1),
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          entry['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Streak
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${entry['streak']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
