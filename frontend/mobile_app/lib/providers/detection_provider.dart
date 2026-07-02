import 'package:flutter/foundation.dart';

import '../models/disease_result.dart';
import '../services/storage_service.dart';

class DetectionProvider extends ChangeNotifier {
  List<DiseaseResult> _history = [];
  DiseaseResult? _latest;
  bool _loaded = false;

  List<DiseaseResult> get history => List.unmodifiable(_history);
  DiseaseResult? get latest => _latest;

  Future<void> loadFromStorage() async {
    if (_loaded) return;
    _history = await StorageService.loadDetectionHistory();
    if (_history.isNotEmpty) _latest = _history.first;
    _loaded = true;
    notifyListeners();
  }

  void addResult(DiseaseResult result) {
    _history.insert(0, result);
    _latest = result;
    StorageService.saveDetectionHistory(_history);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _latest = null;
    StorageService.saveDetectionHistory(_history);
    notifyListeners();
  }
}
