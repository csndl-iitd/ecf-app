// my_home_page.dart
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer';
import 'package:event_tracker/Firebase/FirebaseImageStorage.dart';
import 'package:event_tracker/HIVE/HiveService.dart';
import 'package:event_tracker/eyeGazeTrack/eye_gaze_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:media_projection_screenshot/captured_image.dart';
import 'package:media_projection_screenshot/media_projection_screenshot.dart';
import 'package:flutter/services.dart';
import 'package:seeso_flutter/seeso.dart';
import 'package:seeso_flutter/seeso_plugin_constants.dart';
  // Import the new file

class MyHomePage3 extends StatefulWidget {
  @override
  _MyHomePage3State createState() => _MyHomePage3State();
}

class _MyHomePage3State extends State<MyHomePage3> {
  bool isAccessibilityServiceRunning = false;
  late StreamSubscription<AccessibilityEvent> _accessibilitySubscription;
  List<Map<String, dynamic>> _events = [];
  final HiveService _hiveService = HiveService();
  final _screenshotPlugin2 = MediaProjectionScreenshot();
  FirebaseImageStorage storage = FirebaseImageStorage();
  CapturedImage? image;


  final EyeGazeTracker _eyeGazeTracker = EyeGazeTracker();  // Create an instance

  @override
  void initState() {
    super.initState();
    _eyeGazeTracker.EyeGazeTracking(_updateState);  // Start eye gaze tracking
    _initAccessibilityService();
    _loadEventsFromHive();
  }

  @override
  void dispose() {
    _stopAccessibilityListener();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

 
//accessibility services
  Future<void> _initAccessibilityService() async {
    final _seesoPlugin = SeeSo();
    _seesoPlugin.startCalibration(CalibrationMode.FIVE);
    
    final bool status = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!status) {
      final bool res = await FlutterAccessibilityService.requestAccessibilityPermission();
      
      _screenshotPlugin2.requestPermission();
      await Permission.storage.request();
      final stream = await _screenshotPlugin2.startCapture(x: 0, y: 0, width:1000, height: 2000,);
                  stream?.listen((result) {
                    setState(() {
                      image = CapturedImage.fromMap(Map<String, dynamic>.from(result));
                    });
                  });
      
      if (!res) {
        log('Accessibility permission denied.');
        print('Accessibility permission denied.');
        return;
      }
      
    }
    _startAccessibilityListener();
  }


  void _startAccessibilityListener() async {
    // Check if the service is already running
    if (isAccessibilityServiceRunning) {
      return;
    }
    AccessibilityEvent? lastEvent;
    // Listen to the accessibility events
    _accessibilitySubscription = FlutterAccessibilityService.accessStream.listen((event) async {

      String eventType = event.eventType.toString();
      String windowType = event.windowType.toString();
      String actionType = event.actionType.toString();
      String eventTime = event.eventTime?.toString() ?? 'Unknown';
      String packageName = event.packageName ?? 'Unknown';
      String nodeId = event.nodeId?? 'Unknown';
      ScreenBounds screenbounds = event.screenBounds!;

      // Check if the new event is the same as the last one
      if (lastEvent != null &&
          lastEvent?.eventType == event.eventType &&
          lastEvent?.actionType == event.actionType &&
          lastEvent?.packageName == event.packageName) {
        return; 
      }
      // Update lastEvent
      lastEvent = event;
      print('Event Type: $eventType, Action Type: $actionType');
      print('Event Time: $eventTime, Package Name: $packageName');
      print('screenbounds : ${screenbounds},\n  windowtype: ${windowType}, nodeid: ${nodeId}\n\n');
 
 
      //Store Data in Hive 
      await _hiveService.saveEvent( DateTime.now().toString(),
        {
          'eventtype': eventType,
          'eventtime': eventTime,
          'packageName': packageName,
          'screenbounds':{
            'left': screenbounds.left,
            'right': screenbounds.right,
            'top': screenbounds.top,
            'bottom': screenbounds.bottom,
            'height':screenbounds.height,
            'width':screenbounds.width,
          }
          
        });
      log('Event Type: $eventType, Event Time: $eventTime, Package Name: $packageName, Action Type: $actionType');
      print("\n");

      // Reload events from Hive
       _loadEventsFromHive();
       //detect click events
      if (eventType==EventType.typeViewClicked.toString()|| eventType==EventType.typeViewSelected.toString()) {
        CapturedImage? result = await _screenshotPlugin2.takeCapture(x: 0, y: 0, width: 1000,height:2000);
                  setState(() {
                    image = result;
                  });
        
        storage.pickAndStoreImage(image,eventType,eventTime,packageName,screenbounds);
        print('screenbounds for click event : ${screenbounds}');
        print('Event data Saved for : $eventType');
          }
       else{
        storage.StoreEventData(eventType,eventTime,packageName,screenbounds);
        print('Event data Saved for : $eventType');
       }
    });
    setState(() {
      isAccessibilityServiceRunning = true;
    });
    log('Accessibility event listener started.');
    print('Accessibility event listener started.');
  }



   Future<void> _stopAccessibilityListener() async {
    _accessibilitySubscription.cancel();
    setState(() {
      isAccessibilityServiceRunning = false;
    });
    await _screenshotPlugin2.stopCapture();
    log('Accessibility event listener stopped.');
    print('Accessibility event listener stopped.');
  }

  Future<void> _loadEventsFromHive() async {
    List<Map<String, dynamic>> events = await _hiveService.loadEvents();
    setState(() {
      _events = events;
    });
  }



//UI 
  @override
  Widget build(BuildContext context) {
    double hght = MediaQuery.of(context).size.height;
    double wid = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('User Interaction Tracker'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          image != null
              ? Container(
                  height: hght * 0.4,
                  width: wid * 0.4,
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      border: Border.all(width: 7, color: Colors.black12)),
                  padding: const EdgeInsets.all(6),
                  child: Image.memory(
                    image!.bytes,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(),
          
          SizedBox(
            child: Text('(${_eyeGazeTracker.x},${_eyeGazeTracker.y})'),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  leading: Text(
                    '${event['eventtime'].substring(0, 10)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  title: Text(
                    '\nApp : ${event['packageName'].substring(1 + event['packageName'].lastIndexOf('.')).toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Event Type: ${event['eventtype'].substring(14)}\nEvent Time: ${event['eventtime'].substring(10)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
