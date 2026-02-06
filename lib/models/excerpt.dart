class Excerpt {
  final dynamic id; // Can be int or String (UUID)
  final String text;
  final String bookTitle;
  final String category;

  Excerpt({
    required this.id,
    required this.text,
    required this.bookTitle,
    required this.category,
  });

  factory Excerpt.fromJson(Map<String, dynamic> json) {
    return Excerpt(
      id: json['id'], // Keep as-is (int or String)
      text: json['text'] as String,
      bookTitle: json['book_title'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'book_title': bookTitle,
      'category': category,
    };
  }
}
