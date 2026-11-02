import 'package:flutter_proj/data/models/counter_dto.dart';
import 'package:flutter_proj/models/counter.dart';

class CounterService {
  CounterDto _state = const CounterDto(value: 0);

  Counter get current => Counter(value: _state.value);

  Counter increment() {
    _state = CounterDto(value: _state.value + 1);
    return current;
  }
}
