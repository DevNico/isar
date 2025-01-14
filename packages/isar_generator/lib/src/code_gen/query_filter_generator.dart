import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/code_gen/query_filter_length.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class FilterGenerator {
  FilterGenerator(this.object) : objName = object.dartName;
  final ObjectInfo object;
  final String objName;

  String generate() {
    var code =
        'extension ${objName}QueryFilter on QueryBuilder<$objName, $objName, '
        'QFilterCondition> {';
    for (final property in object.properties) {
      if (property.nullable) {
        code += generateIsNull(property);
      }

      if (!property.isarType.containsFloat &&
          property.isarType != IsarType.object &&
          property.isarType != IsarType.objectList) {
        code += generateEqualTo(property);
      }

      if (property.isarType != IsarType.bool &&
          property.isarType != IsarType.boolList &&
          property.isarType != IsarType.object &&
          property.isarType != IsarType.objectList) {
        code += generateGreaterThan(property);
        code += generateLessThan(property);
        code += generateBetween(property);
      }

      if (property.isarType == IsarType.string ||
          property.isarType == IsarType.stringList) {
        code += generateStringStartsWith(property);
        code += generateStringEndsWith(property);
        code += generateStringContains(property);
        code += generateStringMatches(property);
      }

      if (property.isarType.isList &&
          property.isarType != IsarType.object &&
          property.isarType != IsarType.objectList) {
        code += generateListLength(property);
      }
    }
    return '''
    $code
  }''';
  }

  String caseSensitiveProperty(ObjectProperty p) {
    if (p.isarType == IsarType.string || p.isarType == IsarType.stringList) {
      return 'bool caseSensitive = true,';
    } else {
      return '';
    }
  }

  String caseSensitiveValue(ObjectProperty p) {
    if (p.isarType == IsarType.string || p.isarType == IsarType.stringList) {
      return 'caseSensitive: caseSensitive,';
    } else {
      return '';
    }
  }

  String mPrefix(ObjectProperty p, [bool listAny = true]) {
    final any = listAny && p.isarType.isList ? 'Element' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> '
        '${p.dartName.decapitalize()}$any';
  }

  String generateEqualTo(ObjectProperty p) {
    final optional = caseSensitiveProperty(p);
    return '''
    ${mPrefix(p)}EqualTo(${p.nScalarDartType} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.equalTo(
          property: r'${p.isarName}',
          value: value,
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateGreaterThan(ObjectProperty p) {
    final include = !p.isarType.containsFloat ? 'bool include = false,' : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}GreaterThan(${p.nScalarDartType} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.greaterThan(
          ${!p.isarType.containsFloat ? 'include: include,' : ''}
          property: r'${p.isarName}',
          value: value,
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateLessThan(ObjectProperty p) {
    final include = !p.isarType.containsFloat ? 'bool include = false,' : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}LessThan(${p.nScalarDartType} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.lessThan(
          ${!p.isarType.containsFloat ? 'include: include,' : ''}
          property: r'${p.isarName}',
          value: value,
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateBetween(ObjectProperty p) {
    final include = !p.isarType.containsFloat
        ? 'bool includeLower = true, bool includeUpper = true,'
        : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}Between(${p.nScalarDartType} lower, ${p.nScalarDartType} upper ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.between(
          property: r'${p.isarName}',
          lower: lower,
          includeLower: ${!p.isarType.containsFloat ? 'includeLower' : 'false'},
          upper: upper,
          includeUpper: ${!p.isarType.containsFloat ? 'includeUpper' : 'false'},
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateIsNull(ObjectProperty p) {
    var code = '''
    ${mPrefix(p, false)}IsNull() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(const FilterCondition.isNull(
          property: r'${p.isarName}',
        ));
      });
    }''';
    if (p.isarType.isList && p.isarType != IsarType.byteList) {
      code += '''
      ${mPrefix(p)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.equalTo(
            property: r'${p.isarName}',
            value: null,
          ));
        });
      }''';
    }
    return code;
  }

  String generateStringStartsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}StartsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.startsWith(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringEndsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}EndsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.endsWith(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringContains(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Contains(String value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.contains(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringMatches(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.matches(
          property: r'${p.isarName}',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateListLength(ObjectProperty p) {
    return generateLength(objName, p.dartName,
        (lower, includeLower, upper, includeUpper) {
      return '''
        QueryBuilder.apply(this, (query) {
          return query.listLength(
            r'${p.isarName}',
            $lower,
            $includeLower,
            $upper,
            $includeUpper,
          );
        })''';
    });
  }
}
