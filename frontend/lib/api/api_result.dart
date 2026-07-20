abstract class ApiResult<T, F> {
  const ApiResult();

  F? get failure;
  String? get message;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;
}
