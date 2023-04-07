import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var appbarStyle = GoogleFonts.getFont(
  'Nunito',
  fontSize: 26,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);
var smallText = GoogleFonts.getFont(
  'Nunito',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: Colors.black,
);
var textFieldStyle = GoogleFonts.getFont(
  'Nunito',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0xff6B6B6B),
);
var buttonText = GoogleFonts.getFont(
  'Nunito',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: Colors.white,
);

var decuration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(25),
  boxShadow: [
    BoxShadow(
      blurRadius: 5,
      spreadRadius: 5,
      color: Colors.grey.withOpacity(0.30),
      offset: Offset(3, 3),
    ),
  ],
);
var appColor = Color(0xffD22730);

var rowStyle = GoogleFonts.getFont('Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xff1A1B1B),);
var columnStyle = GoogleFonts.getFont('Nunito', fontSize: 6, fontWeight: FontWeight.w500, color: Color(0xff1A1B1B),);
var indexStyle = GoogleFonts.getFont('Nunito', fontSize: 8, fontWeight: FontWeight.w500, color: Color(0xff1A1B1B),);
