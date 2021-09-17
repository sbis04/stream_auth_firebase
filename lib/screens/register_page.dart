import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/utils/authentication.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authentication = Authentication();
  final _loginFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegistering = false;

  _nameValidator(String? name) {
    if (name == null || name.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  _emailValidator(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter a valid email';
    }
    return null;
  }

  _passwordValidator(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password of 6 characters or more';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                validator: (value) => _nameValidator(value),
                decoration: InputDecoration(hintText: 'Name'),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                validator: (value) => _emailValidator(value),
                decoration: InputDecoration(hintText: 'Email'),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                validator: (value) => _passwordValidator(value),
                decoration: InputDecoration(hintText: 'Password'),
              ),
              SizedBox(height: 16.0),
              _isRegistering
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_loginFormKey.currentState!.validate()) {
                          setState(() {
                            _isRegistering = true;
                          });

                          String? token =
                              await _authentication.registerUsingEmailPassword(
                            context: context,
                            name: _nameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                          );

                          setState(() {
                            _isRegistering = true;
                          });

                          if (token != null) {
                            print('Stream token: $token');
                          }
                        }
                      },
                      child: const Text('Sign Up'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
