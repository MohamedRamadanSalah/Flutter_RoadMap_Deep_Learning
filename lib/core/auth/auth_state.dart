
 
import 'package:testing_state_managment_riverpod/core/auth/user.dart';

sealed class AuthState  {
  const AuthState._();
  const factory AuthState.authenticated({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.loading() = Loading;
}


class Authenticated extends AuthState {
  final User user;
  final String accessToken;
  final String refreshToken;
  const Authenticated({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  }) : super._();
}
class Unauthenticated extends AuthState {
  const Unauthenticated() : super._();
}
class Loading extends AuthState {
  const Loading() : super._();
}


