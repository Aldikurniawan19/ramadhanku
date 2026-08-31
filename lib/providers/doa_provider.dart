import 'package:flutter/material.dart';
import '../data/models/doa_model.dart';
import '../data/services/doa_service.dart';

class DoaProvider extends ChangeNotifier {
  final DoaService _doaService = DoaService();

  List<DoaModel> _doaList = [];
  List<DoaModel> _filteredDoaList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  List<DoaModel> get doaList => _filteredDoaList;
  bool get isLoading => _isLoading;
  int get totalDoaCount => _doaList.length;

  DoaProvider() {
    loadDoaList();
  }

  Future<void> loadDoaList() async {
    _isLoading = true;
    notifyListeners();

    try {
      _doaList = await _doaService.fetchAllDoa();
      _filteredDoaList = List.from(_doaList);
    } catch (_) {
      _doaList = _doaService.fallbackDoaList;
      _filteredDoaList = List.from(_doaList);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchDoa(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredDoaList = List.from(_doaList);
    } else {
      _filteredDoaList = _doaList.where((d) {
        return d.judul.toLowerCase().contains(_searchQuery) ||
            d.terjemah.toLowerCase().contains(_searchQuery) ||
            d.latin.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  void toggleBookmark(dynamic id) {
    final index = _doaList.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = _doaList[index];
      _doaList[index] = item.copyWith(isBookmarked: !item.isBookmarked);
      searchDoa(_searchQuery);
    }
  }
}
