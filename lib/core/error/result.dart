/// Sealed result type carrying either a success value or an [AppFailure].
library;

import 'app_failure.dart';

/// Either an [Ok] success value of type [T] or an [Err] wrapping an
/// [AppFailure]. Used by repository methods so failures stay values (the
/// project convention — see `app_failure.dart`) instead of being thrown.
///
/// Pattern-match at call sites:
///
/// ```dart
/// switch (result) {
///   case Ok<MyType>(value: final v): ...
///   case Err<MyType>(failure: final f): ...
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Success variant of [Result] carrying the produced [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The successful result value.
  final T value;
}

/// Failure variant of [Result] carrying the [AppFailure] the repository
/// produced when mapping a data-source exception.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The structured failure value safe to surface in the UI.
  final AppFailure failure;
}
