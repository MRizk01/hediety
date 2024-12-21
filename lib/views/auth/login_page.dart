import 'package:flutter/material.dart';
import 'package:hediety/controllers/auth_controller.dart';
import 'package:hediety/core/custom_widgets.dart';
import 'package:hediety/views/auth/registration_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               CustomTextFormField(
                key: const Key('email_field'), // Add key here
                controller: emailController,
                labelText: 'Email',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CustomTextFormField(
                 key: const Key('password_field'), // Add key here
                controller: passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CustomElevatedButton(
                key: const Key('login_button'), // Add key here
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _authController.login(emailController.text, passwordController.text);
                      // Navigate to the next screen after successful login
                    } on Exception catch (e) {
                      showNotification(e.toString(), context);
                    }
                  }
                },
                child: const Text('Login'),
              ),
              
              TextButton(
                onPressed: () {
                  // Navigate to RegistrationPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}