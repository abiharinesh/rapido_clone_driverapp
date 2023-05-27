import 'dart:async';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/mainScreens/main_screen.dart';
import 'package:flutter/material.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
 {
  //startTimer is used to hold the current screen for given duration 
  startTimer()
  {
    Timer(const Duration(seconds:3),()async
    
    {
      if(await fAuth.currentUser !=null)
      {

        currentFirebaseUser = fAuth.currentUser;
         Navigator.push(context, MaterialPageRoute(builder: (c)=> const MainScreen()));
      }
      else
      {
         Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));
      }
    });

  }

  @override
  // initState runs first and calls the given functions   
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color:Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("images/logo.png"),
              //add size boxes if needed
              const Text(
                "Rapido Clone App",
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}