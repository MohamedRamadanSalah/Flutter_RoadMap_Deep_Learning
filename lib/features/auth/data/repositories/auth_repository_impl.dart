import 'package:testing_state_managment_riverpod/core/auth/user.dart';
import 'package:testing_state_managment_riverpod/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository{
  @override
  Future<({String accessToken, String refreshToken, User user})> login(String phone, String otp) {
    // get the user from the database and return the access token, refresh token and user
    return Future.delayed(const Duration(seconds: 2), () {
      return (
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: User(
          id: '1',
          name: 'John Doe',
        ),
      );
    });
  }   
 
  }

