import 'package:hive/hive.dart';

class HiveService{
  static const String _boxName = 'Track_Event';
  //Save Events in Hive 
  Future<void> saveEvent(String key, Map<String, dynamic> event) async {
    var box = await Hive.openBox(_boxName);
    await box.put(key, event);
  }
  //Fetrch Events from hive 
  Future<List<Map<String, dynamic>>> loadEvents() async {
    var box = await Hive.openBox(_boxName);
    List<Map<String, dynamic>> events = [];
    for (var key in box.keys) {
      events.add(Map<String, dynamic>.from(box.get(key)));
    }
    return events;
  }
}
