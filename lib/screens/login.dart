import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/services.dart';

class LoginScreen extends StatefulWidget {
  // Creates a dynamic screen that can be changed upon statement
  createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    // If the user is already logged in then go straight to equipment screen
    auth.getUser.then((user) {
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/equipment');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(FontAwesomeIcons.th, size: 150,),
                Text(
                    'Inventory App',
                    style: Theme.of(context).textTheme.headline3
                ),
                Text(
                  'Login to Start',
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                LoginButton(
                  // Google login button
                  text: 'LOGIN WITH GOOGLE',
                  icon: FontAwesomeIcons.google,
                  color: Colors.black45,
                  loginMethod: auth.googleSignIn,
                ),
                LoginButton(
                  // Anonymous login button
                  text: 'Login as a Guest',
                  icon: FontAwesomeIcons.userSecret,
                  color: Colors.grey,
                  loginMethod: auth.anonLogin
                )
              ],
            )
        )
    );
  }
}

// Generic login button with changeable parameters
class LoginButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Function loginMethod;

  const LoginButton(
      {Key key, this.text, this.icon, this.color, this.loginMethod})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: FlatButton.icon(
        padding: EdgeInsets.all(30),
        icon: Icon(icon, color: Colors.white),
        color: color,
        onPressed: () async {
          // Waits that the loginMethod is done and then checks if the user
          // has logged in or if its still not logged (user != null)
          // if the user is logged redirects to equipment page
          var user = await loginMethod();
          if (user != null) {
            // print user to console for debug
            print(user);

            Navigator.pushReplacementNamed(context, '/equipment');
          }
        },
        label: Expanded(
          child: Text('$text', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}