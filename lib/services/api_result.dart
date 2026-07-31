/*
===========================================
MeccsIQ Pro v2.0
Build: #007
Version: v2.0.0
File: api_result.dart
===========================================
*/

class ApiResult<T> {
  const ApiResult({
    required this.success,
    this.data,
    this.message,
  });

  final bool success;

  final T? data;

  final String? message;

  bool get isSuccess => success;

  bool get hasData => data != null;

  factory ApiResult.success(T data) {
    return ApiResult(
      success: true,
      data: data,
    );
  }

  factory ApiResult.error(String message) {
    return ApiResult(
      success: false,
      message: message,
    );
  }
}
