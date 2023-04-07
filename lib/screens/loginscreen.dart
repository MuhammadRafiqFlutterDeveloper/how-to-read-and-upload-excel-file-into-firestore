import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_dos_admin/constant.dart';
import 'package:p_dos_admin/screens/verification.dart';

import '../main.dart';
import 'forgotpassword.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  var _emailController = TextEditingController();
  var _passwordController = TextEditingController();
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    var email = _emailController.text.trim();
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.0, vertical: 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Login',
                      style: GoogleFonts.getFont(
                        'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Image.asset(
                    'assets/images/logo1.png',
                    height: 100,
                    width: 100,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text(
                      "Welcome back!",
                      style: GoogleFonts.getFont(
                        'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 45,
                  ),
                  Container(
                    decoration: decuration,
                    height: 43,
                    child: TextFormField(
                      cursorColor: appColor,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixText: "",
                        prefixStyle: TextStyle(color: appColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        hintText: 'Email',
                        hintStyle: textFieldStyle,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.0),
                  Container(
                    height: 43,
                    decoration: decuration,
                    child: TextFormField(
                      cursorColor: appColor,
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none),
                        hintText: 'Password',
                        hintStyle: textFieldStyle,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: appColor,
                          ),
                        ),
                        contentPadding: EdgeInsets.only(
                            left: 15, top: 15, right: 15, bottom: 15),
                        alignLabelWithHint: true,
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      textAlign: TextAlign.left,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.to(ForgotPassword());
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.getFont(
                          'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: appColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 70.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize:
                          Size(MediaQuery.of(context).size.width - 30, 43),
                    ),
                    onPressed: () {
                      if (_emailController.text.isEmpty) {
                        displayMessage("Please Enter the Email ");
                      } else if (!email.contains('@') ||
                          !email.endsWith('gmail.com')) {
                        displayMessage("Invalid Email");

                        return;
                      } else if (_passwordController.text == '') {
                        displayMessage("Please Enter the Password");
                      } else if (_passwordController.text.length < 6) {
                        displayMessage(
                            'password should be AtLeast 6 Character');
                      } else {
                        Get.to(
                          Verification(
                            email: _emailController.text,
                            password: _passwordController.text,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Login',
                      style: buttonText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
