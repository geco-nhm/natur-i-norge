import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:naturinorge_guide/src/models/variable_steps.dart';

void main() {
  test('parseVariableSteps keeps multi-scale groups (NO-AA shape)', () {
    final decoded = json.decode('''
[
  {
    "maaleskalaNavn": "T1c",
    "maaleskalatypeEnum": "T1c",
    "maaleskalatypeNavn": "Tetthetsskala, 2-logaritmisk",
    "enhetEnum": "T",
    "enhetNavn": "Tetthet",
    "trinn": [
      {"verdi": "15", "navn": ">256", "kode": "15"},
      {"verdi": "0", "navn": "0", "kode": "0"}
    ]
  },
  {
    "maaleskalaNavn": "D0",
    "maaleskalatypeEnum": "D0",
    "maaleskalatypeNavn": "Antallsskala",
    "enhetEnum": "A",
    "enhetNavn": "Antall",
    "trinn": [
      {"verdi": "10", "navn": "<256", "kode": "10"}
    ]
  }
]
''');

    expect(isUndifferentiatedFlatSteps(decoded), isFalse);
    final scales = parseVariableSteps(decoded);
    expect(scales, hasLength(2));
    expect(scales[0].maaleskalaNavn, 'T1c');
    expect(scales[0].trinn, hasLength(2));
    expect(scales[0].displayTitle, 'Måleskala T1c');
    expect(scales[0].displaySubtitle, 'Tetthetsskala, 2-logaritmisk · Tetthet');
    expect(scales[1].maaleskalaNavn, 'D0');
    expect(scales[1].trinn.single.navn, '<256');
  });

  test('legacy flat steps_json is detected and wrapped as one scale', () {
    final decoded = json.decode('''
[
  {"verdi": "15", "navn": ">256", "kode": "15"},
  {"verdi": "14", "navn": ">128–256", "kode": "14"}
]
''');

    expect(isUndifferentiatedFlatSteps(decoded), isTrue);
    final scales = parseVariableSteps(decoded);
    expect(scales, hasLength(1));
    expect(scales.single.maaleskalaNavn, isNull);
    expect(scales.single.trinn, hasLength(2));
    expect(scales.single.trinn.first.verdi, '15');
  });

  test('empty input yields no scales', () {
    expect(parseVariableSteps([]), isEmpty);
    expect(parseVariableSteps(null), isEmpty);
  });
}
