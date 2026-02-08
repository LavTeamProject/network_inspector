import 'package:flutter/material.dart';

class ActivityFilterProvider extends ChangeNotifier {
  List<int?> _selectedStatusCodes = [];
  List<String> _selectedBaseUrls = [];
  List<String> _selectedPaths = [];
  List<String> _selectedMethods = [];

  List<int?> get selectedStatusCodes => _selectedStatusCodes;
  List<String> get selectedBaseUrls => _selectedBaseUrls;
  List<String> get selectedPaths => _selectedPaths;
  List<String> get selectedMethods => _selectedMethods;

  void onChangeSelectedStatusCode(int? statusCode) {
    if (_selectedStatusCodes.contains(statusCode)) {
      _selectedStatusCodes.remove(statusCode);
    } else {
      _selectedStatusCodes.add(statusCode);
    }
    notifyListeners();
  }

  void onChangeSelectedBaseUrl(String baseUrl) {
    if (_selectedBaseUrls.contains(baseUrl)) {
      _selectedBaseUrls.remove(baseUrl);
    } else {
      _selectedBaseUrls.add(baseUrl);
    }
    notifyListeners();
  }

  void onChangeSelectedPath(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    notifyListeners();
  }

  void onChangeSelectedMethod(String method) {
    if (_selectedMethods.contains(method)) {
      _selectedMethods.remove(method);
    } else {
      _selectedMethods.add(method);
    }
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedStatusCodes.clear();
    _selectedBaseUrls.clear();
    _selectedPaths.clear();
    _selectedMethods.clear();
    notifyListeners();
  }

  int get selectedFiltersCount {
    return _selectedStatusCodes.length +
        _selectedBaseUrls.length +
        _selectedPaths.length +
        _selectedMethods.length;
  }

  bool get hasActiveFilters => selectedFiltersCount > 0;
}