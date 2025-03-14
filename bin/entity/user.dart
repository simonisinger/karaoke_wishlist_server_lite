class User {
  final int id;
  final String username;
  final String password;
  final String role;
  final String apiKey;

  User(this.id, this.username, this.password, this.role, this.apiKey);

  static User fromMap(Map data) => User(
      data['id'],
      data['username'],
      data['password'],
      data['role'],
      data['apiKey']
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'role': role,
    'apiKey': apiKey
  };
}