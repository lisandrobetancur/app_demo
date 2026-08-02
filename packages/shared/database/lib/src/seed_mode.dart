/// Boot seeding mode, selected with `--dart-define=SEED_MODE=...`.
enum SeedMode {
  /// Database starts with the deterministic demo content (default).
  demo,

  /// Database starts empty, to walk through every empty state.
  empty;

  bool get isDemo => this == SeedMode.demo;

  bool get isEmpty => this == SeedMode.empty;

  /// Parses the `--dart-define` value; unknown values fall back to [demo].
  static SeedMode parse(String raw) =>
      raw.trim().toLowerCase() == 'empty' ? SeedMode.empty : SeedMode.demo;
}
