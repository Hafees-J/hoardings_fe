import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString("access");
    final refreshToken = prefs.getString("refresh");

    // no access token saved → not logged in
    if (accessToken == null) return false;

    // check if access token still valid
    bool valid = await ApiService.isTokenValid(accessToken);

    if (valid) return true;

    // try refreshing
    if (refreshToken != null) {
      bool refreshed = await ApiService.refreshAccessToken();
      return refreshed;
    }

    // nothing works → logged out
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoardings App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const HomePage();
          }
          return LoginPage();
        },
      ),
    );
  }
}
