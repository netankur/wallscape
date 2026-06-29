import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _apiKey = 'YOUR API KEY'; // PASTE API KEY HERE

  static Future<List<dynamic>> fetchWallpapers({
    String query = 'Wallpapers',
    int page = 1,
    String orientation = 'All',
  }) async {
    // Pexels /search endpoint is required to use orientation filters
    String searchQuery = query.isEmpty || query.toLowerCase() == 'curated'
        ? 'Wallpapers'
        : query;
    String url =
        'https://api.pexels.com/v1/search?query=$searchQuery&per_page=30&page=$page';

    if (orientation != 'All') {
      url += '&orientation=${orientation.toLowerCase()}';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': _apiKey},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['photos'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
