// same name

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  String? prop1;

  @Name('prop1')
  String? prop2;
}
