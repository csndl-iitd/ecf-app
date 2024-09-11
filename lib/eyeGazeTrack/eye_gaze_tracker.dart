import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // Ensure Firebase is initialized
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:seeso_flutter/event/calibration_info.dart';
import 'package:seeso_flutter/event/gaze_info.dart';
import 'package:seeso_flutter/seeso.dart';
import 'package:seeso_flutter/seeso_plugin_constants.dart';

class EyeGazeTracker {
  
  final _seesoPlugin = SeeSo();
  
  DatabaseReference refDB = FirebaseDatabase.instance.ref('EyeGazeData');

  double x = 0.0, y = 0.0;
  MaterialColor gazeColor = Colors.red;
  double nextX = 0, nextY = 0, calibrationProgress = 0.0;

  Future<void> EyeGazeTracking(void Function() onUpdate) async {
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();

    await _seesoPlugin.requestCameraPermission();
    print(await _seesoPlugin.checkCameraPermission());

    _seesoPlugin.startCalibration(CalibrationMode.FIVE);

    _seesoPlugin.getCalibrationEvent().listen((event) {
      CalibrationInfo caliInfo = CalibrationInfo(event);
      if (caliInfo.type == CalibrationType.CALIBRATION_NEXT_XY) {
        nextX = caliInfo.nextX!;
        nextY = caliInfo.nextY!;
        calibrationProgress = 0.0;
        Future.delayed(const Duration(milliseconds: 500), () {
          _seesoPlugin.startCollectSamples();
          onUpdate();
        });
      }
    });
    await dotenv.load(fileName: ".env");
    String _licenseKey = dotenv.env['MY_LICENSE_KEY']!;
    await _seesoPlugin.initGazeTracker(licenseKey: _licenseKey);
    _seesoPlugin.startTracking();

    _seesoPlugin.getGazeEvent().listen((event) async {
      GazeInfo info = GazeInfo(event);
      if (info.trackingState == TrackingState.SUCCESS) {
        x = info.x;
        y = info.y;
        gazeColor = Colors.green;
        //print('gaze : ($x,$y)');
      } else {
        x = 0.0;
        y = 0.0;
        gazeColor = Colors.red;
        //print('gaze not found : ($x,$y)');
      }
      onUpdate();

      Map<String, dynamic> details = {
        'Time': DateTime.now().toIso8601String(), // Use ISO8601 format for time
        'x_coordinate': x,
        'y_coordinate': y,
      };
      String key = DateTime.now().millisecondsSinceEpoch.toString();
      Map<String, dynamic> eyeGaze = {
        'EventDetails': details,
      };
      await refDB.child(key).set(eyeGaze);
    });
  }
}
