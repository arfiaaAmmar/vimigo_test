import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimigo_test/main.dart';

// ignore: must_be_immutable
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
          image: AssetImage('assets/images/onboarding_image.png'),
          fit: BoxFit.cover,
        )),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          // navigate to the main screen of the app
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isFirstOpen", false);

          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceScreen(),
            ),
          );
        },
        child: const Text(
          "Get Started",
          style: TextStyle(
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
