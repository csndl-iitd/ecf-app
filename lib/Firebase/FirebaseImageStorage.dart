import 'dart:io';
import 'dart:typed_data';
import 'package:event_tracker/editImage/blur.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:media_projection_screenshot/captured_image.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseImageStorage {
  Image_Process p= new Image_Process();
  Uint8List? _processedImage;
  final FirebaseStorage storage = FirebaseStorage.instance;
  DatabaseReference reference = FirebaseDatabase.instance.ref('TrackUserInteractions');
  DatabaseReference reference2 = FirebaseDatabase.instance.ref('ClickedEvent');

  Future<String> uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference storageReference = storage.ref().child('images/$fileName');
    final UploadTask uploadTask = storageReference.putFile(imageFile);

    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    final imageUrl = await taskSnapshot.ref.getDownloadURL();
    print(imageUrl);

    return imageUrl;
  }

  Future<void> storeImageData(String imageUrl, Map<String, dynamic> otherDetails) async {
   String key = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, dynamic> data = {
      'imageUrl': imageUrl,
      'EventDetails': otherDetails,
    };
    await reference.child(key).set(data);
    await reference2.child(key).set(data);
  }

  Future<void> pickAndStoreImage(CapturedImage? image1, String eventtype, String eventtime , String packagename,ScreenBounds screenbounds) async {
    final imageBytes = image1!.bytes;
    print(imageBytes);
    print("ss recieved  ${double.parse(screenbounds.left.toString())}");
    //print("${double.parse(screenbounds.left.toString()).runtimeType}");
    Uint8List edited = await p.process_Image(imageBytes,double.parse(screenbounds.left.toString()), double.parse(screenbounds.top.toString()),double.parse(screenbounds.height.toString()), double.parse(screenbounds.width.toString()));
    
    print("processed img recieved");

    final output =await getTemporaryDirectory();
    var filePath ="${output.path}/${DateTime.now().millisecondsSinceEpoch}.png"; 
    final file = File(filePath);
    await file.writeAsBytes(edited);

      String imageUrl = await uploadImage(file);
      Map<String, dynamic> otherDetails = {
        'eventtype': eventtype,
        'eventtime': eventtime,
        'packageName': packagename,
        'screenbounds':{
            'left': screenbounds.left,
            'right': screenbounds.right,
            'top': screenbounds.top,
            'bottom': screenbounds.bottom,
            'height':screenbounds.height,
            'width':screenbounds.width,
          }
      };
      await storeImageData(imageUrl, otherDetails);

      print('Image uploaded and data stored successfully!');
    }


    
  Future<void> StoreEventData( String eventtype, String eventtime , String packagename,ScreenBounds screenbounds) async {
   
      Map<String, dynamic> otherDetails = {
        'eventtype': eventtype,
        'eventtime': eventtime,
        'packageName': packagename,
        'screenbounds':{
            'left': screenbounds.left,
            'right': screenbounds.right,
            'top': screenbounds.top,
            'bottom': screenbounds.bottom,
            'height':screenbounds.height,
            'width':screenbounds.width,
          }
      };
      String key = DateTime.now().millisecondsSinceEpoch.toString();
      Map<String, dynamic> data = {'EventDetails': otherDetails,};
      await reference.child(key).set(data);
      print('Image uploaded and data stored successfully!');
    }
}
