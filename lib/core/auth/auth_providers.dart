import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/core/auth/auth_state.dart';
import 'package:testing_state_managment_riverpod/core/auth/user.dart';
part 'auth_providers.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  Future<void> login(String accessToken, String refreshToken, User user) async {
    state = const AuthState.loading();
    await Future.delayed(const Duration(seconds: 2));
    state = AuthState.authenticated(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}

@riverpod
User? currentUser(Ref ref) {
  final authstate = ref.watch(authControllerProvider);
  return switch (authstate) {
    Authenticated(:final user) => user,
    _ => null,
  };
}

@riverpod
String? authToken(Ref ref) {
  final authstate = ref.watch(authControllerProvider);
  return switch (authstate) {
    Authenticated(:final accessToken) => accessToken,
    _ => null,
  };
}
