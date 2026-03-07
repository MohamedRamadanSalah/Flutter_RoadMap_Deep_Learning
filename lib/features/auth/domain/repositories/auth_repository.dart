import 'package:testing_state_managment_riverpod/core/auth/user.dart';

abstract class AuthRepository {
  Future<({String accessToken, String refreshToken, User user})> login(
    String phone,
    String otp,
  );
}
