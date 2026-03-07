import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_state_managment_riverpod/core/auth/auth_providers.dart';
import 'package:testing_state_managment_riverpod/core/auth/auth_state.dart';
import 'package:testing_state_managment_riverpod/features/auth/data/repositories/auth_repository_impl.dart';

class LoginScreen extends ConsumerWidget {
  final repository = AuthRepositoryImpl();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is Loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: phoneController,
            decoration: InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: otpController,
            decoration: InputDecoration(labelText: 'OTP'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await repository.login(
                phoneController.text,
                otpController.text,
              );
              await ref
                  .read(authControllerProvider.notifier)
                  .login(result.accessToken, result.refreshToken, result.user);
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}
