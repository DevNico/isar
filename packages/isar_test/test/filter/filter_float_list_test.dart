import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_float_list_test.g.dart';

@Collection()
class FloatModel {
  FloatModel(this.list);
  Id? id;

  @Index(type: IndexType.value)
  List<float?>? list;

  @override
  String toString() {
    return '{id: $id, list: $list}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && doubleListEquals(other.list, list);
}

void main() {
  group('Float list filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel objEmpty;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      objEmpty = FloatModel([]);
      obj1 = FloatModel([1.1, 3.3]);
      obj2 = FloatModel([null]);
      obj3 = FloatModel([null, -1000]);
      objNull = FloatModel(null);

      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('.elementGreaterThan()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementGreaterThan(1.1).tFindAll(),
        [obj1],
      );
      await qEqualSet(col.where().listElementGreaterThan(4).tFindAll(), []);

      // filters
      await qEqual(
        col.filter().listElementGreaterThan(1.1).tFindAll(),
        [obj1],
      );
      await qEqual(col.filter().listElementGreaterThan(4).tFindAll(), []);
    });

    isarTest('.elementLessThan()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementLessThan(1.1).tFindAll(),
        [obj2, obj3],
      );
      await qEqualSet(col.where().listElementLessThan(null).tFindAll(), []);

      // filters
      await qEqual(
        col.filter().listElementLessThan(1.1).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(col.filter().listElementLessThan(null).tFindAll(), []);
    });

    isarTest('.anyBetween()', () async {
      // where clauses
      await qEqualSet(col.where().listElementBetween(1, 5).tFindAll(), [obj1]);
      await qEqualSet(col.where().listElementBetween(5, 10).tFindAll(), []);

      // filters
      await qEqual(col.filter().listElementBetween(1, 5).tFindAll(), [obj1]);
      await qEqual(col.filter().listElementBetween(5, 10).tFindAll(), []);
    });

    isarTest('.elementIsNull()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementIsNull().tFindAll(),
        [obj2, obj3],
      );

      // filters
      await qEqual(
        col.filter().listElementIsNull().tFindAll(),
        [obj2, obj3],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementIsNotNull().tFindAll(),
        [obj1, obj3],
      );
    });
  });
}
