import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'entities/news_model.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsModel> _newsPosts = [];
  List<NewsModel> _favoritePosts = [];
  bool _isLoading = false;

  List<NewsModel> get newsPosts => _newsPosts;
  List<NewsModel> get favoritePosts => _favoritePosts;
  bool get isLoading => _isLoading;

  Future<void> fetchNews() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetching from WordPress API with _embed to get author and media info
      final response = await http.get(
        Uri.parse('https://pharmacysyria.com/wp-json/wp/v2/posts?_embed'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _newsPosts = data.map((json) => NewsModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching news: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(NewsModel post) {
    final index = _favoritePosts.indexWhere((p) => p.id == post.id);
    if (index >= 0) {
      _favoritePosts.removeAt(index);
    } else {
      _favoritePosts.add(post);
    }
    notifyListeners();
  }

  bool isFavorite(int id) {
    return _favoritePosts.any((p) => p.id == id);
  }
}
