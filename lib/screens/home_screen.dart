import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart'; // Make sure to change 'AuraX' to 'Wallscape' inside your settings text!

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const HomePage(), const FavoritesPage(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white38,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2), activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill), label: ''),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), activeIcon: Icon(CupertinoIcons.heart_solid), label: ''),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), activeIcon: Icon(CupertinoIcons.settings_solid), label: ''),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> wallpapers = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  
  int currentPage = 1;
  String currentQuery = 'Curated';
  String currentOrientation = 'All'; // Image Size/Orientation filter
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Expanded Versatile Categories
  final List<String> categories = ['Curated', 'AMOLED', 'Cyberpunk', 'Minimal', 'Nature', 'Architecture', 'Space', 'Cars', 'Neon', 'Abstract'];
  final List<String> orientations = ['All', 'Portrait', 'Landscape', 'Square'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (isInfiniteScrollEnabled.value && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500 && !isFetchingMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) setState(() { isLoading = true; currentPage = 1; wallpapers.clear(); });
    final data = await ApiService.fetchWallpapers(query: currentQuery, page: currentPage, orientation: currentOrientation);
    setState(() { wallpapers.addAll(data); isLoading = false; });
  }

  Future<void> _loadMoreData() async {
    setState(() => isFetchingMore = true);
    currentPage++;
    final data = await ApiService.fetchWallpapers(query: currentQuery, page: currentPage, orientation: currentOrientation);
    setState(() { wallpapers.addAll(data); isFetchingMore = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallscape')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) { if (val.trim().isNotEmpty) { currentQuery = val; _loadData(isRefresh: true); } },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search masterpieces...',
                prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          // Versatile Categories Scroll
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = currentQuery == categories[index];
                return GestureDetector(
                  onTap: () { currentQuery = categories[index]; _searchController.clear(); _loadData(isRefresh: true); },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.white24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(categories[index], style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Orientation / Size Filter Row
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: orientations.length,
              itemBuilder: (context, index) {
                final isSelected = currentOrientation == orientations[index];
                return GestureDetector(
                  onTap: () { currentOrientation = orientations[index]; _loadData(isRefresh: true); },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        Icon(isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54),
                        const SizedBox(width: 4),
                        Text(orientations[index], style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Grid
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : MasonryGridView.count(
                    controller: _scrollController,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    padding: const EdgeInsets.all(16),
                    itemCount: wallpapers.length + (isFetchingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= wallpapers.length) return const Center(child: CupertinoActivityIndicator(color: Colors.white));
                      final wallpaper = wallpapers[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(wallpaper: wallpaper))),
                        child: Hero(
                          tag: '${wallpaper['id']}_$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: wallpaper['src']['large'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => AspectRatio(aspectRatio: (index % 3 == 0) ? 0.7 : 1.2, child: Container(color: const Color(0xFF141414))),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
