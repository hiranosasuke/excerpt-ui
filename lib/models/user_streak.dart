class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastActivityDate;

  UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity_date'] as String?,
    );
  }
}
