/// Distinguishes a scheduled review from a voluntary free-practice attempt.
///
/// The value is persisted in `reviews.review_kind`; keep the order stable.
enum ReviewKind {
  scheduled,
  freePractice;

  int get value => index;

  static ReviewKind fromValue(int value) {
    return value == freePractice.index
        ? ReviewKind.freePractice
        : ReviewKind.scheduled;
  }
}
