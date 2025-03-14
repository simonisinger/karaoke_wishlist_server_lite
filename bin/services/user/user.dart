import 'dart:math';

import 'package:crypt/crypt.dart';
import 'package:mysql1/mysql1.dart';

import '../../core/exception.dart';
import '../../core/mysql.dart';
import '../../entity/user.dart';

class UserService {
  Future<User> login(String username, String password) async {
    Results user = await mySql.query("SELECT id, password FROM user WHERE username = ?", [username]);
    if (user.isEmpty) {
      throw KaraokeException('user not found');
    }
    bool credentialsValid = Crypt(user.first['password']).match(password);
    if (!credentialsValid) {
      throw KaraokeException('invalid credentials');
    }
    await mySql.query("UPDATE user SET api_key = ? WHERE id = ?", [_generateApiKey(), user.first['id']]);

    return await getUser(user.first['id']);
  }

  Future<User> createUser(String username, String password, String role) async {
    String encryptedPassword = Crypt.sha256(password, salt: _generateApiKey()).toString();
    bool userExists = (await mySql.query("SELECT id FROM user WHERE username = ?", [username])).isNotEmpty;
    if (userExists) {
      throw KaraokeException('User with this name already exists');
    }
    Results userInsert = await mySql.query("INSERT INTO user (username, password, role) VALUE (?,?,?)", [username, encryptedPassword, role]);
    return User(userInsert.insertId!, username, encryptedPassword, role, '');
  }

  Future<void> deleteUser(int id) async {
    await mySql.query("DELETE FROM user WHERE id = ?", [id]);
  }

  Future<User> getUser(int id) async {
    Results userRaw = await mySql.query("SELECT * FROM user WHERE id = ?", [id]);
    if (userRaw.isEmpty) {
      throw KaraokeException('user not found');
    }
    return User(id, userRaw.first['username'], userRaw.first['password'], userRaw.first['role'], userRaw.first['api_key']);
  }

  Future<User> getUserByApiKey(String apiKey) async {
    Results user = await mySql.query("SELECT * FROM user WHERE api_key = ?", [apiKey]);

    if (user.isEmpty) {
      throw KaraokeException('User by api key not found');
    }

    ResultRow userRaw = user.first;
    return User(userRaw['id'], userRaw['username'], userRaw['password'], userRaw['role'], userRaw['api_key']);
  }

  Future<List<User>> getUsers() async {
    Results userRaw = await mySql.query("SELECT * FROM user");

    return userRaw.map((e) => User(e['id'], e['username'], e['password'], e['role'], e['api_key'] ?? '')).toList();
  }

  String _generateApiKey() {
    var r = Random();
    return String.fromCharCodes(List.generate(10, (index) => r.nextInt(33) + 89));
  }
}