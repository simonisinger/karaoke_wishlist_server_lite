import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
late final MySqlConnection mySql;

initMysql() async {
  var settings = ConnectionSettings(
      host: dotenv.env['DATABASE_HOST']!,
      port: int.tryParse(dotenv.env['DATABASE_PORT']!)!,
      user: dotenv.env['DATABASE_USER'],
      password: dotenv.env['DATABASE_PASSWORD'],
      db: dotenv.env['DATABASE_NAME'],
  );
  mySql = await MySqlConnection.connect(settings);
}