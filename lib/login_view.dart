import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:habits/service_locator.dart';
import 'api_client.dart';
import 'constants.dart' as Constants;

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  bool isLoading = false;

  late ApiClient apiClient;

  @override
  void initState() {
    super.initState();
    apiClient = getIt.get<ApiClient>();
  }

  void handleLogin() async {
    // Handle login logic here
    setState(() {
      isLoading = true;
    });
    try {
      await apiClient.login(_usernameController.text, _passwordController.text);
      setState(() {
        isLoading = false;
      });
      widget.onLoginSuccess();
    } on DioException catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
      if (e.response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: Unknown error')),
        );
        return;
      } else {
        var mess = e.response!.data;
        try {
          if (mess['non_field_errors'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: ${mess["non_field_errors"][0]}'),
              ),
            );
            return;
          }
        } catch (ex) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login failed: $mess')));
        }
      }
    }

    // Save a dummy token
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Constants.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                filled: true,
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL (optional)',
                filled: true,
                border: OutlineInputBorder(),
                hint: Text(Constants.baseApiUrl),
              ),
              obscureText: false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
