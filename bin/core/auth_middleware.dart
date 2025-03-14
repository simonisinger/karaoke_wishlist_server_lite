import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/user/user.dart';

class AuthMiddleware {
  final UserService _userService = UserService();

  static List<String> publicRoutes = [
    'song/wish',
    'contest/application/create',
    'song/search',
    'login',
    'setting'
  ];
  Middleware checkAuth() {
    return (Handler handler) {
      return (Request request) async {
        if (publicRoutes.contains(request.url.toString())) {
          final response = await handler(request);
          return response;
        }
        if (request.headers.containsKey('x-api-key')) {
          try {
            await _userService.getUserByApiKey(request.headers['x-api-key']!);
          } catch(exception) {
            return Response.unauthorized(jsonEncode({
              'status': 'error',
              'message': 'invalid key'
            }));
          }
          try {
            final response = await handler(request);
            return response;
          } catch(exception) {
            return Response.ok(jsonEncode({
              'status': 'error',
              'message': 'server error'
            }));
          }
        }
        return Response.unauthorized(null);
      };
    };

  }
}