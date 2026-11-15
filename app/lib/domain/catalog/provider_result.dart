enum ProviderFailureKind {
  network,
  timeout,
  rateLimited,
  credentialsMissing,
  authentication,
  invalidResponse,
  unavailable,
}

enum ProviderHealth { healthy, degraded, offline, disabled, unknown }

/// Typed provider outcome. Adapter exceptions and response bodies must not
/// cross this boundary.
sealed class ProviderResult<T> {
  const ProviderResult();
}

final class ProviderSuccess<T> extends ProviderResult<T> {
  const ProviderSuccess(this.value);

  final T value;
}

final class ProviderNoResults<T> extends ProviderResult<T> {
  const ProviderNoResults();
}

final class ProviderUnsupported<T> extends ProviderResult<T> {
  const ProviderUnsupported(this.capability);

  final String capability;
}

final class ProviderFailure<T> extends ProviderResult<T> {
  const ProviderFailure(this.kind, {this.retryAfter});

  final ProviderFailureKind kind;
  final Duration? retryAfter;

  bool get isRetryable => switch (kind) {
    ProviderFailureKind.network ||
    ProviderFailureKind.timeout ||
    ProviderFailureKind.rateLimited ||
    ProviderFailureKind.unavailable => true,
    ProviderFailureKind.credentialsMissing ||
    ProviderFailureKind.authentication ||
    ProviderFailureKind.invalidResponse => false,
  };
}
