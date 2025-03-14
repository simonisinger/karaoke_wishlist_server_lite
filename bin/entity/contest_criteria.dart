class ContestCriteria {
  final int id;
  final String name;
  final double weight;

  ContestCriteria(this.id, this.name, this.weight);

  static ContestCriteria fromMap(Map data) => ContestCriteria(
      data['id'],
      data['name'],
      data['weight']
  );

  Map toMap() => {
    'id': id,
    'name': name,
    'weight': weight,
  };
}