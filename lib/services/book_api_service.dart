import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/book_model.dart';

class BookApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all categories ordered by name
  static Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch books, optionally filtered by category
  static Future<List<BookModel>> getBooks({String? categoryId}) async {
    var query = _supabase.from('books').select();

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'ALL') {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
