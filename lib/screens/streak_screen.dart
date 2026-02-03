import 'package:flutter/material.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  // Sample leaderboard data
  static const List<Map<String, dynamic>> leaderboard = [
    {'name': 'Sarah M.', 'streak': 45, 'isCurrentUser': false},
    {'name': 'Alex K.', 'streak': 32, 'isCurrentUser': false},
    {'name': 'Jordan L.', 'streak': 28, 'isCurrentUser': false},
    {'name': 'Taylor W.', 'streak': 21, 'isCurrentUser': false},
    {'name': 'Morgan P.', 'streak': 18, 'isCurrentUser': false},
    {'name': 'Riley S.', 'streak': 14, 'isCurrentUser': false},
    {'name': 'Quinn D.', 'streak': 9, 'isCurrentUser': false},
    {'name': 'You', 'streak': 3, 'isCurrentUser': true},
    {'name': 'Casey R.', 'streak': 2, 'isCurrentUser': false},
    {'name': 'Jamie T.', 'streak': 1, 'isCurrentUser': false},
  ];

  @override
  Widget build(BuildContext context) {
    const currentStreak = 3;
    const longestStreak = 7;

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
                  const Text(
                    '$currentStreak',
                    style: TextStyle(
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
                    child: const Text(
                      'Longest: $longestStreak days',
                      style: TextStyle(
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
              itemCount: leaderboard.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
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
