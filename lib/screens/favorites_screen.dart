import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';
import 'detail_screen.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 26)),
      ),
      body: ValueListenableBuilder<List<dynamic>>(
        valueListenable: favoriteWallpapers,
        builder: (context, favorites, child) {
          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorites yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final wallpaper = favorites[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(wallpaper: wallpaper)),
                ),
                child: Hero(
                  tag: 'fav_${wallpaper['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: wallpaper['src']['large'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
