class BookModel {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? categoryId;
  final String thumbnailUrl;
  final String epubUrl;
  final int? fileSizeBytes;
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.categoryId,
    required this.thumbnailUrl,
    required this.epubUrl,
    this.fileSizeBytes,
    required this.createdAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String,
      epubUrl: json['epub_url'] as String,
      fileSizeBytes: json['file_size_bytes'] != null
          ? (json['file_size_bytes'] as num).toInt()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
