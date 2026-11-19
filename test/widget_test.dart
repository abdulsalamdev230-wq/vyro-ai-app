// VYRO AI — Widget tests
//
// These tests verify that key screens build and render without crashing.
// Firebase is NOT initialized in tests, so screens that call AuthProvider
// initialize() are exercised only for their build layout (no sign-in flows).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vyro_ai/screens/login_screen.dart';
import 'package:vyro_ai/screens/register_screen.dart';
import 'package:vyro_ai/core/providers/auth_provider.dart';

void main() {
  testWidgets('LoginScreen builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AuthProvider.instance,
        child: MaterialApp(
          home: SizedBox(
            width: 1200,
            height: 900,
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Social login heading should be present on left panel.
    expect(find.text('Bring Your Stories to Life.'), findsOneWidget);
    expect(find.text('Create magical 3D animated stories with the power of AI.'), findsOneWidget);

    // Social buttons should be present on right panel.
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    // Welcome heading.
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('LoginScreen email login form renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AuthProvider.instance,
        child: MaterialApp(
          home: SizedBox(
            width: 1200,
            height: 900,
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Email form fields should be visible on the login page.
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Link to the separate register page.
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('RegisterScreen builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AuthProvider.instance,
        child: MaterialApp(
          home: SizedBox(
            width: 1200,
            height: 900,
            child: RegisterScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Create-account heading and full signup form.
    expect(find.text('Create Your Vyro AI Account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    // Social buttons + link back to login.
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
