import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_state_managment_riverpod/core/auth/auth_providers.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Ref ref;
  AuthInterceptor(this.ref);
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = ref.read(authTokenProvider);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        print('Token refreshed! Retrying request...');
        // You would retry the request here
        // handler.resolve(await _retry(err.requestOptions));
        return;
      }
      // If refresh fails, logout
      await ref.read(authControllerProvider.notifier).logout();
      print('Refresh failed. User logged out.');
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    // Simulate a refresh: randomly succeed or fail
    await Future.delayed(const Duration(seconds: 1));
    return false; // Change to true to simulate success
  }
}
