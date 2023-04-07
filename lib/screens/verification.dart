import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:p_dos_admin/screens/readData.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant.dart';
import '../main.dart';

class Verification extends StatefulWidget {
  String email;
  String password;

  Verification({
    required this.email,
    required this.password,
  });

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  bool _isLoading = false;
  String savedOtp = '';

  var _codeController = TextEditingController();

  @override
  void initState() {
    print(widget.email);
    sendOtpCode();
    super.initState();
  }

  @override
  void dispose() {
    savedOtp;
    _codeController;
    _isLoading;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 1.20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Verification",
                    style: appbarStyle,
                  ),
                ),
              ),
              SizedBox(
                height: 2,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 1.20,
                height: 30,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter the OTP code sent to your email ",
                    style: GoogleFonts.getFont(
                      'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 30),
                child: Pinput(
                  textInputAction: TextInputAction.next,
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  length: 4,
                  obscureText: false,
                  closeKeyboardWhenCompleted: true,
                  defaultPinTheme: PinTheme(
                    margin: EdgeInsets.all(8),
                    height: 45,
                    width: 45,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: appColor,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(blurRadius: 2, color: Colors.grey),
                      ],
                    ),
                  ),
                  onTap: () {
                    loadValue("otp2");
                  },
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "Did not receive a code?",
                style: GoogleFonts.getFont('Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                child: TextButton(
                  onPressed: () {
                    sendOtpCode().whenComplete((){
                      displayMessage("Otp Sent to your Email Successfully");
                    });
                  },
                  child: Text(
                    "RESEND",
                    style: GoogleFonts.getFont(
                      'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: appColor,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              SizedBox(
                height: 43,
                width: MediaQuery.of(context).size.width -90,
                child: MaterialButton(
                  onPressed: () async {
                    loadValue("otp2");
                    if (_codeController.text == "") {
                      displayMessage('Put the correct Otp');
                    } else if (_codeController.text == savedOtp) {
                      setState(() {
                        _isLoading = true;
                      });
                      await createUser();
                      setState(() {
                        _isLoading = false;
                      });
                    } else {
                      displayMessage('Some Thing Went Wrong');
                    }
                  },
                  color: appColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  child: _isLoading
                      ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    'Done',
                    style: buttonText,
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendOtpCode() async {
    String otp = generateOTP();
    Map<String, String> body = {
      'to': widget.email,
      'message': "Hey \n" +
          "P-Dos" +
          ",\nyou're almost ready to start find Solution of Diagnosis. Simply Copy this code \n" +
          otp +
          "\n and paste in your  App for signup completion ",
      'subject': "P-Dos"
    };

    final response = await http.post(
        Uri.parse(
            "https://apis.appistaan.com/mailapi/index.php?key=sk286292djd926d"),
        body: body);

    print(response);

    if (response.statusCode == 200) {
      saveValue('otp2', otp);
      print("sent");
      print(otp.toString());
      displayMessage("Otp Sent to your Email Successfully");
    }
  }

  Future<void> saveValue(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  // Method to load the value from shared preferences
  Future<void> loadValue(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedOtp = prefs.getString(key)!;
      print(savedOtp);
    });
  }

  String generateOTP() {
    int length = 4; // Length of the OTP
    String characters = '0123456789'; // Characters to use for the OTP
    String otp = '';
    for (int i = 0; i < length; i++) {
      otp += characters[Random().nextInt(characters.length)];
      print(otp);

    }
    return otp;
  }

  Future<void> createUser() async {
    try {

      String myEmail = widget.email;
      String password = widget.password;

      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: myEmail, password: password)
          .then(
        (value) {
          var _auth = FirebaseAuth.instance;
          final User? user = _auth.currentUser;
          final _uid = user!.uid;
          setState(
            () {
              _isLoading = false;
            },
          );
          FirebaseFirestore.instance.collection('users').doc(_uid).set(
            {
              'uid': _uid,
              'email': widget.email.trim(),
              'password': widget.password.trim(),
              'currantDate': Timestamp.now(),
            },
          );
          Get.to(
            ExcelCsvReader(),
          );
        },
      );
    } catch (error) {
      displayMessage(
        'This Email Already Exist',
      );
    }
  }
}
