import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String supabaseUrl = 'https://waerdqekcoxmbneamajv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhZXJkcWVrY294bWJuZWFtYWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0OTE0MTgsImV4cCI6MjA4MzA2NzQxOH0.agDEldzJKXgcRRLl70o5D2NCfuaq05flBVQFt7-Y-9M';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;

  static String? get userId => currentUser?.id;

  static String? get accessToken => client.auth.currentSession?.accessToken;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.dailybeliefs://login-callback/',
    );
  }

  /// Generates a cryptographically secure random nonce
  static String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign In failed - no identity token received');
    }

    return await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
