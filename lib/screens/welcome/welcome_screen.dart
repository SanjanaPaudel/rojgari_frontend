import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
const WelcomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF6F3FF),
body: SafeArea(
child: SingleChildScrollView(
child: Column(
children: [
const SizedBox(height: 0),

// =========================
// TOP SECTION (UNCHANGED)
// =========================
Stack(
clipBehavior: Clip.none,
children: [
Column(
children: [
const SizedBox(height: 120),

Container(
width: 45,
height: 4,
decoration: BoxDecoration(
color: Colors.orange,
borderRadius: BorderRadius.circular(10),
),
),

const SizedBox(height: 18),

const Text(
"Connecting skilled hands\nwith every home",
textAlign: TextAlign.center,
style: TextStyle(fontSize: 22),
),
],
),

Positioned(
top: 0,
left: 0,
right: 0,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Image.asset(
"assets/images/logo_r.png",
height: 85,
),
Transform.translate(
offset: const Offset(0, -29),
child: Image.asset(
"assets/images/logo_text.png",
height: 70,
),
),
],
),
),
],
),

const SizedBox(height: 0),

// =========================
// IMAGE SECTION
// =========================
Stack(
clipBehavior: Clip.none,
children: [
Column(
children: [
Stack(
alignment: Alignment.center,
children: [
Image.asset(
"assets/images/bg.png",
width: double.infinity,
height: 380,
fit: BoxFit.cover,
),

Transform.translate(
offset: const Offset(0, 10),
child: Image.asset(
"assets/images/illustration.png",
height: 320,
),
),
],
),

const SizedBox(height: 80),
],
),

Positioned(
top: 300,
left: 0,
right: 0,
child: Container(
width: double.infinity,
padding: const EdgeInsets.fromLTRB(
24,
12,
24,
30,
),
decoration: const BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.only(
topLeft: Radius.circular(35),
topRight: Radius.circular(35),
),
),
child: Column(
children: [
const Text(
"Welcome to Rojgari",
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.bold,
color: Color(0xff1D1B39),
),
),

const SizedBox(height: 8),

const Text(
"How would you like to continue?",
style: TextStyle(
fontSize: 18,
color: Colors.black54,
),
),

const SizedBox(height: 7),

Row(
children: [                              Expanded(
child: InkWell(
borderRadius: BorderRadius.circular(22),
onTap: () {
// TODO: Navigate to Customer Screen
// Example:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => const CustomerLoginScreen(),
//   ),
// );
},
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 22,
),
decoration: BoxDecoration(
color: const Color(0xffF4F0FF),
borderRadius: BorderRadius.circular(22),
),
child: Column(
children: [
Container(
height: 70,
width: 70,
decoration: const BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
),
child: const Icon(
Icons.person_outline,
color: Color(0xff5C31D6),
size: 38,
),
),

const SizedBox(height: 20),

const Text(
"Customer",
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Color(0xff5C31D6),
),
),

const SizedBox(height: 10),

Container(
margin: const EdgeInsets.only(top: 6),
height: 55,
width: 55,
decoration: const BoxDecoration(
color: Color(0xff5C31D6),
shape: BoxShape.circle,
),
child: const Icon(
Icons.arrow_forward,
color: Colors.white,
),
),
],
),
),
),
),

const SizedBox(width: 18),                              Expanded(
child: InkWell(
borderRadius: BorderRadius.circular(22),
onTap: () {
// TODO: Navigate to Technician Screen
// Example:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => const TechnicianLoginScreen(),
//   ),
// );
},
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 22,
),
decoration: BoxDecoration(
color: const Color(0xffFFF6EE),
borderRadius: BorderRadius.circular(22),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
height: 70,
width: 70,
decoration: const BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
),
child: const Icon(
Icons.work_outline,
color: Colors.orange,
size: 36,
),
),

const SizedBox(height: 20),

const Text(
"Technician",
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.orange,
),
),

const SizedBox(height: 10),

Container(
margin: const EdgeInsets.only(top: 6),
height: 55,
width: 55,
decoration: const BoxDecoration(
color: Colors.orange,
shape: BoxShape.circle,
),
child: const Icon(
Icons.arrow_forward,
color: Colors.white,
),
),
],
),
),
),
),
],
),

const SizedBox(height: 26),                          const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.verified_user_outlined,
        color: Color(0xff6E4AE3),
        size: 22,
      ),
      SizedBox(width: 8),
      Text(
        "Verified professionals. Safe services.",
        style: TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    ],
  ),
],
),
),
),
],
),
],
),
),
),
);
}
}