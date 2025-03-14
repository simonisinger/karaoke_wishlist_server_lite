import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../entity/user.dart';
import '../services/user/user.dart';

class UserController {
  final UserService _userService = UserService();

  Future<Response> login(Request request) async{
    Map json = jsonDecode((await request.readAsString()));
    User user = await _userService.login(json['username'], json['password']);
    return Response.ok(jsonEncode(user.toMap()));
  }

  Future<Response> createUser(Request request) async {
    Map json = jsonDecode((await request.readAsString()));
    User user = await _userService.createUser(json['username'], json['password'], json['role']);
    return Response.ok(jsonEncode(user.toMap()));
  }

  Future<Response> deleteUser(Request request) async {
    Map json = jsonDecode((await request.readAsString()));
    await _userService.deleteUser(json['userId']);
    return Response.ok(
        jsonEncode({
          'status': 'success'
        })
    );
  }

  Future<Response> getUsers(Request request) async {
    return Response.ok(
        jsonEncode((await _userService.getUsers()).map((e) => e.toMap()).toList())
    );
  }
}