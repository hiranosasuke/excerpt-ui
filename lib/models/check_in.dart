import 'excerpt.dart';

class CheckIn {
  final String id;
  final String userId;
  final dynamic excerptId; // Can be int or String (UUID)
  final String checkInDate;
  final String? notes;
  final Excerpt? excerpt;

  CheckIn({
    required this.id,
    required this.userId,
    required this.excerptId,
    required this.checkInDate,
    this.notes,
    this.excerpt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      excerptId: json['excerpt_id'], // Keep as-is (int or String)
      checkInDate: json['check_in_date'] as String,
      notes: json['notes'] as String?,
      excerpt: json['excerpts'] != null
          ? Excerpt.fromJson(json['excerpts'])
          : null,
    );
  }
}
