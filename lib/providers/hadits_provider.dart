import 'package:flutter/material.dart';
import '../data/models/hadits_model.dart';
import '../data/services/hadits_service.dart';

class HaditsProvider extends ChangeNotifier {
  final HaditsService _haditsService = HaditsService();

  List<HaditsModel> _haditsList = [];
  List<HaditsModel> _filteredList = [];
  bool _isLoading = false;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  String _selectedBook = 'bukhari';

  List<HaditsModel> get haditsList => _filteredList;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedBook => _selectedBook;
  int get totalHaditsCount => _haditsList.length;

  final List<String> categories = [
    'Semua',
    'Puasa',
    'Sahur',
    'Ramadhan',
    'Akhlak',
    'Sedekah',
    'Ilmu',
    'Al-Qur\'an',
    'Sholat',
    'Dzikir',
    'Niat',
  ];

  HaditsProvider() {
    loadHadits();
  }

  Future<void> loadHadits({String book = 'bukhari'}) async {
    _selectedBook = book;
    _isLoading = true;
    notifyListeners();

    try {
      _haditsList = await _haditsService.fetchHadits(book: book);
      _applyFilter();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void searchHadits(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredList = _haditsList.where((h) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          h.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesQuery = _searchQuery.isEmpty ||
          h.title.toLowerCase().contains(_searchQuery) ||
          h.idTranslation.toLowerCase().contains(_searchQuery) ||
          h.book.toLowerCase().contains(_searchQuery) ||
          h.number.toString() == _searchQuery;

      return matchesCategory && matchesQuery;
    }).toList();
  }
}
