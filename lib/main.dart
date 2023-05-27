import 'package:drivers_app/infoHandler/app_info.dart';
import 'package:drivers_app/splashScreen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MyApp(
      //this child is important to run provider 
      child:ChangeNotifierProvider(
        create: (context) => AppInfo(),
      //after this we can use MaterialApp in other child 
        child: MaterialApp(
        title: 'Drivers App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MySplashScreen(),
        debugShowCheckedModeBanner: false,
          ),
      ),
    )
  );
}



class MyApp extends StatefulWidget
 
{

  final Widget? child;
  const MyApp({super.key, this.child});
  //this function is used to restart the app we can call this function anywhere in app
  static void RestartApp(BuildContext context)
  {
    context.findAncestorStateOfType<_MyAppState>()!.restartApp();
  }
 

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> 
{
  Key key = UniqueKey();
  void restartApp()
  {
    setState(() {
       key = UniqueKey();
    });

  }
  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key:key,
      child: widget.child!,
    ) ;
  }
}


