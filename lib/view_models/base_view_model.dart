import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  Object? _error;

  bool get isLoading => _isLoading;

  Object? get error => _error;

  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @protected
  void setError(Object? value) {
    _error = value;
    notifyListeners();
  }
}
