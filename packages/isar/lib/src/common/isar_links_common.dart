import 'dart:collection';

import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_base_impl.dart';

const bool _kIsWeb = identical(0, 0.0);

/// @nodoc
abstract class IsarLinksCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with IsarLinks<OBJ>, SetMixin<OBJ> {
  final _objects = <Id, OBJ>{};

  /// @nodoc
  final addedObjects = HashSet<OBJ>.identity();

  /// @nodoc
  final removedObjects = HashSet<OBJ>.identity();

  @override
  bool isLoaded = false;

  @override
  bool get isChanged => addedObjects.isNotEmpty || removedObjects.isNotEmpty;

  Map<Id, OBJ> get _loadedObjects {
    if (isAttached && !isLoaded && !_kIsWeb) {
      loadSync();
    }
    return _objects;
  }

  @override
  void attach(
    IsarCollection<dynamic> sourceCollection,
    IsarCollection<OBJ> targetCollection,
    String linkName,
    int? objectId,
  ) {
    super.attach(sourceCollection, targetCollection, linkName, objectId);

    _applyAddedRemoved();
  }

  @override
  Future<void> load({bool overrideChanges = false}) async {
    final objects = await filter().findAll();
    _applyLoaded(objects, overrideChanges);
  }

  @override
  void loadSync({bool overrideChanges = false}) {
    final objects = filter().findAllSync();
    _applyLoaded(objects, overrideChanges);
  }

  void _applyLoaded(List<OBJ> objects, bool overrideChanges) {
    _objects.clear();
    for (final object in objects) {
      final id = getId(object);
      if (id != null) {
        _objects[id] = object;
      }
    }

    if (overrideChanges) {
      addedObjects.clear();
      removedObjects.clear();
    } else {
      _applyAddedRemoved();
    }

    isLoaded = true;
  }

  void _applyAddedRemoved() {
    for (final object in addedObjects) {
      final id = getId(object);
      if (id != null) {
        _objects[id] = object;
      }
    }

    for (final object in removedObjects) {
      final id = getId(object);
      if (id != null) {
        _objects.remove(id);
      }
    }
  }

  @override
  Future<void> save() async {
    if (!isChanged) {
      return;
    }

    await update(link: addedObjects, unlink: removedObjects);

    addedObjects.clear();
    removedObjects.clear();
    isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    updateSync(link: addedObjects, unlink: removedObjects);

    addedObjects.clear();
    removedObjects.clear();
    isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await update(reset: true);
    clear();
    isLoaded = true;
  }

  @override
  void resetSync() {
    updateSync(reset: true);
    clear();
    isLoaded = true;
  }

  @override
  bool add(OBJ value) {
    if (isAttached) {
      final id = getId(value);
      if (id != null) {
        if (_objects.containsKey(id)) {
          return false;
        }
        _objects[id] = value;
      }
    }

    removedObjects.remove(value);
    return addedObjects.add(value);
  }

  @override
  bool contains(Object? element) {
    requireAttached();

    if (element is OBJ) {
      final id = getId(element);
      if (id != null) {
        return _loadedObjects.containsKey(id);
      }
    }
    return false;
  }

  @override
  Iterator<OBJ> get iterator => _loadedObjects.values.iterator;

  @override
  int get length => _loadedObjects.length;

  @override
  OBJ? lookup(Object? element) {
    requireAttached();

    if (element is OBJ) {
      final id = getId(element);
      if (id != null) {
        return _loadedObjects[id];
      }
    }
    return null;
  }

  @override
  bool remove(Object? value) {
    if (value is! OBJ) {
      return false;
    }

    if (isAttached) {
      final id = getId(value);
      if (id != null) {
        if (isLoaded && !_objects.containsKey(id)) {
          return false;
        }
        _objects.remove(id);
      }
    }

    addedObjects.remove(value);
    return removedObjects.add(value);
  }

  @override
  Set<OBJ> toSet() {
    requireAttached();
    return HashSet(
      equals: (o1, o2) => getId(o1) == getId(o2),
      hashCode: (o) => getId(o)!,
      isValidKey: (o) => o is OBJ && getId(o) != null,
    )..addAll(_loadedObjects.values);
  }
}
