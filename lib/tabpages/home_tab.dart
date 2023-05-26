import 'dart:async';

import 'package:drivers_app/assistants/assistant_methods.dart';
import 'package:drivers_app/assistants/black_theme_google_map.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/push_notifications/push_notification_system.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  _HomeTabPageState createState() => _HomeTabPageState();
}


class _HomeTabPageState extends State<HomeTabPage>
{
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

   //geolocator has default function called position we can get user location from it.. 

   //geolocator has default function called geolocator that gets the users location..
   var geolocator = Geolocator();

   LocationPermission? _locationPermission;

    //variables for drive online and offline
    String statusText = "Now Offline";
    Color buttonColor = Colors.grey;
    bool isDriverActive = false;

    //request location permission
  checkIfLocationPermissionAllowed() async
  {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied)
      {
        _locationPermission = await Geolocator.requestPermission();
      }
  }

  // current user position
  locateDriverPosition() async
  {
      //getting user location from geolocator and assigning to user current position
      Position cPosition =  await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      driverCurrentPosition = cPosition;
      // getting the lat and lng 
       LatLng latLngPosition = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
      // setting the camera position 
       CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 14);
      //updating the camera when ever location gets changed.
       newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoOrdinates(driverCurrentPosition!,context);
       print("this is your address="+ humanReadableAddress);

      
  } 

    readCurrentDriverInformation() async
  {

      await FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .once()
        .then((DatabaseEvent snap)
    {
      if(snap.snapshot.value != null)
      {
        onlineDriverData.id = (snap.snapshot.value as Map)["id"];
        onlineDriverData.name = (snap.snapshot.value as Map)["name"];
        onlineDriverData.phone = (snap.snapshot.value as Map)["phone"];
        onlineDriverData.email = (snap.snapshot.value as Map)["email"];
        onlineDriverData.car_color = (snap.snapshot.value as Map)["car_details"]["car_color"];
        onlineDriverData.car_model = (snap.snapshot.value as Map)["car_details"]["car_model"];
        onlineDriverData.car_number = (snap.snapshot.value as Map)["car_details"]["car_number"];

         driverVehicleType = (snap.snapshot.value as Map)["car_details"]["type"];

        print("Car Details :: ");
        print(onlineDriverData.car_color);
        print(onlineDriverData.car_model);
        print(onlineDriverData.car_number);
      }
    });
    currentFirebaseUser = fAuth.currentUser;
    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializeCloudMessaging(context);
    pushNotificationSystem.generateAndGetToken();
  }


        @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    readCurrentDriverInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller)
          {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;

            //black theme google map
            blackThemeGoogleMap(newGoogleMapController);

            locateDriverPosition();
          },
        ),

        //ui for online and offline driver

         statusText != "Now Online"
            ? Container(
                height: MediaQuery.of(context).size.height,
                width: double.infinity,
                color: Colors.black87,
              )
            : Container(),

        //button for online offline driver

           Positioned(
          top: statusText != "Now Online"
              ? MediaQuery.of(context).size.height * 0.46
              : 25,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: ()
                {
                 if(isDriverActive != true) //offline
                  {
                    driverIsOnlineNow();
                    updateDriversLocationAtRealTime();

                    setState(() {
                      statusText = "Now Online";
                      isDriverActive = true;
                      buttonColor = Colors.transparent;
                    });

                    //display Toast
                    Fluttertoast.showToast(msg: "you are Online Now");
                  }

                   else //online
                  {
                    driverIsOfflineNow();

                    setState(() {
                      statusText = "Now Offline";
                      isDriverActive = false;
                      buttonColor = Colors.grey;
                    });

                    //display Toast
                    Fluttertoast.showToast(msg: "you are Offline Now");
                  }

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: statusText != "Now Online"
                    ? Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                            color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.phonelink_ring,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //saving driver current location in the database using geofire

  driverIsOnlineNow() async
  {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = pos;

    Geofire.initialize("activeDrivers");

    Geofire.setLocation(
        currentFirebaseUser!.uid,
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    ref.set("idle"); //searching for ride request
    ref.onValue.listen((event) { });
  }

  //updating drivers current location in database at realtime

   updateDriversLocationAtRealTime()
  {
    streamSubscriptionPosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
          driverCurrentPosition = position;

          if(isDriverActive == true)
          {
            Geofire.setLocation(
                currentFirebaseUser!.uid,
                driverCurrentPosition!.latitude,
                driverCurrentPosition!.longitude
            );
          }

          LatLng latLng = LatLng(
              driverCurrentPosition!.latitude,
              driverCurrentPosition!.longitude,
          );

          newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

    driverIsOfflineNow()
  {
    Geofire.removeLocation(currentFirebaseUser!.uid);

    DatabaseReference? ref = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");
    ref.onDisconnect();
    ref.remove();
    ref = null;

    //refresh
    Future.delayed(const Duration(milliseconds: 2000), ()
    {
      //SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      SystemNavigator.pop();
    });
  }

}
