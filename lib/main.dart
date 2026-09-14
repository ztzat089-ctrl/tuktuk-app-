import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/captain/captain_dashboard_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TukTukApp());
}

class TukTukApp extends StatelessWidget {
  const TukTukApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TukTuk تكتك',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFF7B500),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF7B500),
          primary: const Color(0xFFF7B500),
        ),
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      locale: const Locale('ar'),
      builder: (context, child) {
        // فرض اتجاه RTL بالكامل بالتطبيق
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

/// يقرر أي شاشة يفتح حسب حالة تسجيل الدخول ونوع الحساب (زبون / كابتن)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // مستخدم مسجل دخول -> نجيب نوع حسابه من Firestore
        return FutureBuilder<String?>(
          future: FirebaseService.getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data;
            if (role == 'captain') {
              return const CaptainDashboardScreen();
            } else if (role == 'customer') {
              return const CustomerHomeScreen();
            } else {
              // حساب بدون نوع محدد -> نرجعه لتسجيل الدخول
              return const WelcomeScreen();
            }
          },
        );
      },
    );
  }
}
