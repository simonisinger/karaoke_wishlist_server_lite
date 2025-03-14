class Setting {
  final int id;
  final String name;
  final String value;

  Setting(this.id, this.name, this.value);

  static Setting fromMap(Map data) => Setting(
      data['id'],
      data['name'],
      data['value']
  );

  Map toMap() => {
    'id': id,
    'name': name,
    'value': value
  };
}