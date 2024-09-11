import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ImageProcessingPage extends StatefulWidget {
  final double x, y, height, width;

  ImageProcessingPage({
    Key? key,
    required this.x,
    required this.y,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  _ImageProcessingPageState createState() => _ImageProcessingPageState();
}

class _ImageProcessingPageState extends State<ImageProcessingPage> {
  ui.Image? img1;
  ui.Image? img2;
  Uint8List? _processedImageBytes;
  Uint8List? _blurredImageBytes;
  Uint8List? _savedImageBytes;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      print("step 1");
      final ByteData data = await rootBundle.load('assets/images/b.png');
      final Uint8List bytes = data.buffer.asUint8List();
      print(bytes);
      img.Image? image = img.decodeImage(bytes);
      print("step 2");
      if (image == null) {
        throw Exception('Failed to decode images.');
      }
      print("step 3");
      img.Image blurredImage = img.gaussianBlur(image, radius: 10);
      Uint8List blurredBytes = Uint8List.fromList(img.encodePng(blurredImage));
      print("step 4");
      int _x = widget.x.toInt();
      int _y = widget.y.toInt();
      int hght = widget.height.toInt();
      int wid = widget.width.toInt();
      img.Image croppedImage = img.copyCrop(image, x: _x, y: _y, width: wid, height: hght);
      Uint8List croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));
      print("step 5");
      final Completer<ui.Image> completer1 = Completer();
      ui.decodeImageFromList(blurredBytes, completer1.complete);
      final ui.Image image1 = await completer1.future;
      print("step 6");
      final Completer<ui.Image> completer2 = Completer();
      ui.decodeImageFromList(croppedBytes, completer2.complete);
      final ui.Image image2 = await completer2.future;
      print("step 7");
      setState(() {
        img1 = image1;
        img2 = image2;
        _processedImageBytes = croppedBytes;
        _blurredImageBytes = blurredBytes;
        print("step 8");
      });
      print("step 9");
      await _saveImage();
    } catch (e) {
      print('Error processing image: $e');
    }
  }

  Future<void> _saveImage() async {
    if (img1 == null || img2 == null) return;
    print("step 10");
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(Offset(0, 0), Offset(img1!.width.toDouble(), img1!.height.toDouble())),
        
      );
     print("step 11");
      // Draw blurred background image
      canvas.drawImage(img1!, Offset.zero, Paint());

      // Draw cropped image on top
      canvas.drawImageRect(
        img2!,
        Rect.fromLTWH(0, 0, img2!.width.toDouble(), img2!.height.toDouble()),
        Rect.fromLTWH(widget.x, widget.y, widget.width, widget.height),
        Paint(),
      );
      print("step 12");
      // Draw red rectangle
      Rect rect = Rect.fromLTWH(widget.x, widget.y, widget.width, widget.height);
      Paint paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawRect(rect, paint);
      print("step 13");
      final picture = recorder.endRecording();
      final img = await picture.toImage(img1!.width, img1!.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      print("step 14");
      setState(() {
        _savedImageBytes = byteData?.buffer.asUint8List();
      });
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Blur and Crop Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              await _saveImage();
              if (_savedImageBytes != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image saved successfully!')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 10),
              
              if (_savedImageBytes != null)
                Image.memory(
                  _savedImageBytes!,
                  fit: BoxFit.cover,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

