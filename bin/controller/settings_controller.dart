import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/setting/setting.dart';

class SettingsController {
  final SettingService _settingService = SettingService();
  Future<Response> getSettings(Request request) async =>
      Response.ok(
          jsonEncode(
              (await _settingService.getSettings())
                  .map((e) => e.toMap()).toList()
          )
      );

  Future<Response> setSetting(Request request) async {
    Map json = jsonDecode((await request.readAsString()));
    await _settingService.setSetting(json['name'], json['value']);
    return Response.ok(jsonEncode({
      'status': 'success'
    }));
  }
}