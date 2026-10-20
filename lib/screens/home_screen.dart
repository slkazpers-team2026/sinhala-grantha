import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/book_model.dart';
import '../services/book_api_service.dart';
import '../services/drm_service.dart';
import '../widgets/home_ad_banner.dart';
import '../widgets/book_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<CategoryModel> _categories = [];
  List<BookModel> _books = [];
  String _selectedCategoryId = 'ALL';
  bool _isLoading = true;
  String? _errorMessage;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enforce DRM screen security across the app
    DrmService.secureScreen();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _bannerKey = UniqueKey();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await BookApiService.getCategories();
      final books = await BookApiService.getBooks(
        categoryId: _selectedCategoryId == 'ALL' ? null : _selectedCategoryId,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _books = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'පොත් පූරණය කිරීම අසාර්ථක විය. කරුණාකර ජාලය පරීක්ෂා කරන්න.';
        });
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Colors.indigoAccent),
            SizedBox(width: 8),
            Text(
              'සිංහල ග්‍රන්ථ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.indigoAccent,
        backgroundColor: const Color(0xFF1E293B),
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Category Chips Selector
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == 'ALL';
                      return ChoiceChip(
                        label: const Text('සියලු පොත්'),
                        selected: isSelected,
                        selectedColor: Colors.indigoAccent,
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.indigoAccent
                              : const Color(0xFF334155),
                        ),
                        onSelected: (_) => _onCategorySelected('ALL'),
                      );
                    }

                    final category = _categories[index - 1];
                    final isSelected = _selectedCategoryId == category.id;

                    return ChoiceChip(
                      label: Text(category.name),
                      selected: isSelected,
                      selectedColor: Colors.indigoAccent,
                      backgroundColor: const Color(0xFF1E293B),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.indigoAccent
                            : const Color(0xFF334155),
                      ),
                      onSelected: (_) => _onCategorySelected(category.id),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),

            // Main Book Grid Content
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                        ),
                        child: const Text('නැවත උත්සාහ කරන්න'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_books.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.library_books, size: 48, color: Colors.white24),
                      SizedBox(height: 12),
                      Text(
                        'මෙම වර්ගයේ පොත් නොමැත.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return BookCard(book: _books[index]);
                    },
                    childCount: _books.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFF0F172A),
          child: HomeAdBanner(key: _bannerKey),
        ),
      ),
    );
  }
}
