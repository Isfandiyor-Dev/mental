/// Randomness as an injected capability, so sequence generation is fully
/// deterministic under test.
abstract interface class RandomSource {
  /// Uniform integer in `[0, max)`.
  int nextInt(int max);

  bool nextBool();
}
