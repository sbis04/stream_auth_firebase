import 'package:flutter/material.dart';
import 'package:stream_auth_firebase/screens/register_page.dart';
import 'package:stream_auth_firebase/utils/authentication.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authentication = Authentication();
  final _loginFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSigningIn = false;
  bool _isCheckingUser = true;
  bool _isSignedIn = false;

  checkIfUserSignedIn() async {
    bool signedInState = await _authentication.isSignedIn(context);

    setState(() {
      _isCheckingUser = false;
      _isSignedIn = signedInState;
    });
  }

  _emailValidator(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }

  _passwordValidator(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    checkIfUserSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Login'),
      ),
      body: _isCheckingUser
          ? Center(child: CircularProgressIndicator())
          : _isSignedIn
              ? Center(
                  child: Icon(
                    Icons.check,
                    size: 30,
                    color: Colors.green,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextFormField(
                          controller: _emailController,
                          validator: (value) => _emailValidator(value),
                          decoration: InputDecoration(hintText: 'Email'),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) => _passwordValidator(value),
                          decoration: InputDecoration(hintText: 'Password'),
                        ),
                        SizedBox(height: 16.0),
                        _isSigningIn
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () async {
                                  if (_loginFormKey.currentState!.validate()) {
                                    setState(() {
                                      _isSigningIn = true;
                                    });

                                    await _authentication
                                        .signInUsingEmailPassword(
                                      context: context,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );

                                    setState(() {
                                      _isSigningIn = false;
                                    });
                                  }
                                },
                                child: const Text('Sign In'),
                              ),
                        SizedBox(height: 16.0),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          ),
                          child: Text('Don\'t have an account? Sign Up'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
