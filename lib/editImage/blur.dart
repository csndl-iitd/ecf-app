import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class Image_Process {
  Future<Uint8List> process_Image(Uint8List img_bytes, double x, double y, double height, double width) async {
    try {
      img.Image? image = img.decodeImage(img_bytes);
      print('step1');
      if (image == null) {
        throw Exception('Failed to decode images.');
      }
      print('step2');
      img.Image blurredImage = img.gaussianBlur(image, radius: 15);
      Uint8List blurredBytes = Uint8List.fromList(img.encodePng(blurredImage));
      print('step3');
      int _x = x.toInt();
      int _y = y.toInt();
      int hght = height.toInt();
      int wid = width.toInt();

      img.Image croppedImage = img.copyCrop(image, x: _x, y: _y, width: wid, height: hght);

      Uint8List croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));
      print('step4');
      final Completer<ui.Image> completer1 = Completer();
      ui.decodeImageFromList(blurredBytes, completer1.complete);
      final ui.Image image1 = await completer1.future;
      print('step5');
      final Completer<ui.Image> completer2 = Completer();
      ui.decodeImageFromList(img_bytes, completer2.complete);
      final ui.Image image2 = await completer2.future;
      print('step6');
      final recorder = ui.PictureRecorder();


      final canvas = Canvas(
        recorder,
        Rect.fromPoints(Offset(0, 0), Offset(image1.width.toDouble(), image1.height.toDouble())),
      );


      print('step8');
      // Draw blurred background image
      canvas.drawImage(image1, Offset.zero, Paint());
    //double croppedImageX = x * (image2.width / image.width);
    //double croppedImageY = y * (image2.height / image.height);

      // Draw cropped image on top
      canvas.drawImageRect(
        image2,
        Rect.fromLTWH(x, y, width, height),
        Rect.fromLTWH(x, y , width, height),
        Paint(),
      );

     print('step9');


     Rect rect = Rect.fromLTWH(x, y, width, height);
      Paint paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawRect(rect, paint);
      print('step10');
      final picture = recorder.endRecording();
      final finalimg = await picture.toImage(image1.width, image1.height);
      final byteData = await finalimg.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
      //return await _saveImage(image1, image2, x, y, height, width);
    } catch (e) {
      print('Error processing image: $e');
      rethrow;
    }
  }


}
