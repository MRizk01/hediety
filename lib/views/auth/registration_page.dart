import 'package:flutter/material.dart';
import 'package:hediety/controllers/auth_controller.dart';
import 'package:hediety/core/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

    Future<void> registerUser(BuildContext context) async {
        if (_formKey.currentState!.validate()) {
            try {
              final userCredential = await _authController.register(emailController.text.trim(), passwordController.text.trim());
             
                if (userCredential.user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userCredential.user!.uid)
                        .set({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'email': emailController.text.trim(),
                    });
                    if (mounted){
                      showNotification('User registered successfully!', context);
                    }
                }
            } on Exception catch (e) {
                String errorMessage = "Registration failed.";
                if (e.toString().contains('weak-password')) {
                   errorMessage = 'The password provided is too weak.';
                } else if (e.toString().contains('email-already-in-use')) {
                    errorMessage = 'The account already exists for that email.';
                } else if (e.toString().contains('invalid-email')) {
                  errorMessage = 'The email address is not valid.';
                }
               showNotification(errorMessage, context);
            } catch (e) {
               showNotification('An unexpected error occurred.', context);
            }
        }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
                CustomTextFormField(
                controller: nameController,
                labelText: 'Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
               CustomTextFormField(
                controller: phoneController,
                labelText: 'Phone',
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
               CustomTextFormField(
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
                onPressed: () => registerUser(context),
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}