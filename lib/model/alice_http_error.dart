class AliceHttpError {
  dynamic error;
  StackTrace? stackTrace;
  int status = 0;
  dynamic body;
  Map<String, String>? headers;
}
