import 'package:flutter_proj/data/services/counter_service.dart';
import 'package:flutter_proj/models/counter.dart';
import 'package:flutter_proj/view_models/base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({CounterService? counterService})
    : _counterService = counterService ?? CounterService() {
    counter = _counterService.current;
  }

  final CounterService _counterService;

  late Counter counter;

  void increment() {
    counter = _counterService.increment();
    notifyListeners();
  }
}
