final class Consts {
  Consts._();

  /// Empty function constant
  static void doNothing() {}

  /// About network request
  static const request = (
  baseUrl: "http://10.9.17.94:8888/api/v1",
  socketBaseUrl: "http://10.9.17.94:8888",
  minWaitingTime: Duration(milliseconds: 500),
  cachedTime: Duration(milliseconds: 2000),
  sendTimeout: Duration(seconds: 5),
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 5),
  successCode: 200,
  pageSize: 10,
  );
}