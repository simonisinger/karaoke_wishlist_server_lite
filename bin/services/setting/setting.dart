import 'package:mysql1/mysql1.dart';

import '../../core/exception.dart';
import '../../core/mysql.dart';
import '../../entity/setting.dart';

class SettingService {
  Future<List<Setting>> getSettings() async {
    Results results = await mySql.query("SELECT * FROM settings");
    return results.map((e) => Setting(e['id'], e['name'], e['value'])).toList();
  }

  Future<Setting> getSetting(String name) async {
    Results results = await mySql.query("SELECT * FROM settings WHERE name = ?", [name]);
    if (results.isEmpty) {
      throw KaraokeException('Setting $name not found');
    }
    ResultRow row = results.first;
    return Setting(row['id'], name, row['value']);
  }

  Future<void> setSetting(String name, String value) async {
    await mySql.query("UPDATE settings SET value = ? WHERE name = ?", [value, name]);
  }
}