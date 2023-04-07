import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p_dos_admin/constant.dart';

import '../main.dart';

class ForgotPassword extends StatefulWidget {
  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: formkey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Forgot Password',
                  style: appbarStyle,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter your email to recover your password ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(
                height: 70,
              ),
              Container(
                height: 43,
                decoration: decuration,
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: appColor,
                  controller: emailCont,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.only(
                      left: 10,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Email',
                    hintStyle: textFieldStyle,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Email Required";
                    } else
                      return null;
                  },
                ),
              ),
              SizedBox(
                height: 110,
              ),
              MaterialButton(
                onPressed: () => forgotPassword(),
                color: appColor,
                elevation: 4,
                minWidth: MediaQuery.of(context).size.width - 10,
                height: 43,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        'Send',
                        style: buttonText,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  var emailCont = TextEditingController();
  Future<void> forgotPassword() async {
    try {
      String email = emailCont.text.trim();

      // Check if email is valid
      if (!email.contains('@') || !email.endsWith('gmail.com')) {
        displayMessage("Invalid Email");

        return;
      }
      setState(() {
        _isLoading = true;
      });
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email)
          .then((value) {
        displayMessage(
            "Reset email was sent. Please check your email to reset your password.");
      });
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      displayMessage("This Email Doesn't Exist in Firebase");
    }
  }

// Future<void> forgotPassword() async {
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //
  //     await FirebaseAuth.instance
  //         .sendPasswordResetEmail(email: emailCont.text)
  //         .then((value) {
  //       displayMessage(
  //           "Reset email was sent Please check your Email reset your Password");
  //     });
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   } catch (error) {
  //     displayMessage(error.toString());
  //   }
  // }
}
