import 'dart:math';

import '../../domain/services/random_source.dart';

class DartRandomSource implements RandomSource {
  DartRandomSource([int? seed]) : _random = Random(seed);

  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  bool nextBool() => _random.nextBool();
}
