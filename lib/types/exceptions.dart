import "package:dio/dio.dart";

class LogOutException implements Exception {
  const LogOutException();
}

class CfWrapperInterceptor extends Interceptor {
  @override
  void onResponse(
      final Response response, final ResponseInterceptorHandler handler) {
    if (response.data.toString().contains('class="cf-wrapper"')) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: "Cloudflare return an error",
          type: DioExceptionType.badResponse,
        ),
      );
    } else {
      handler.next(response);
    }
  }
}
