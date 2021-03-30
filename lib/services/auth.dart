import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

// Login/logout google service, used to authenticate users to their database
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<FirebaseUser> get getUser => _auth.currentUser();
  // Can use either future or stream

  Stream<FirebaseUser> get user => _auth.onAuthStateChanged;

  Future<FirebaseUser> anonLogin() async {
    AuthResult result = await _auth.signInAnonymously();
    FirebaseUser user = result.user;

    // returns anon user bound to device info
    return user;
  }

  Future<FirebaseUser> googleSignIn() async {
    try {
      // Opens up the google signin popup and waits to get an okay response
      GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;

      // Declaring credentials
      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken
      );

      AuthResult result = await _auth.signInWithCredential(credential);
      FirebaseUser user = result.user;

      // returns google account user
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}