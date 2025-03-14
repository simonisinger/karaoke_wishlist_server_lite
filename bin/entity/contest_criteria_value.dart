import 'application.dart';
import 'contest_criteria.dart';
import 'user.dart';

class ContestCriteriaValue {
  final int id;
  final Application application;
  final User user;
  final ContestCriteria contestCriteria;
  final double rating;

  ContestCriteriaValue(this.id, this.application, this.user, this.contestCriteria, this.rating);

  static ContestCriteriaValue fromMap(Map data) => ContestCriteriaValue(
      data['id'],
      Application.fromMap(data['application']),
      User.fromMap(data['user']),
      ContestCriteria.fromMap(data['contestCriteria']),
      data['rating']
  );

  Map toMap() => {
    'id': id,
    'application': application.toMap(),
    'user': user.toMap(),
    'contestCriteria': contestCriteria.toMap(),
    'rating': rating
  };
}