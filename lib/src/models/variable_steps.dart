/// Parsed representation of `nin_variables.steps_json`.
///
/// New scrapes store a list of måleskala groups. Older DBs may still have a
/// flat list of `{verdi, navn, kode}` entries; [parseVariableSteps] accepts both.
class VariableStep {
  final String? verdi;
  final String? navn;
  final String? kode;

  const VariableStep({this.verdi, this.navn, this.kode});

  factory VariableStep.fromJson(Map<String, dynamic> json) {
    return VariableStep(
      verdi: json['verdi']?.toString(),
      navn: json['navn']?.toString(),
      kode: json['kode']?.toString(),
    );
  }
}

class VariableScale {
  final String? maaleskalaNavn;
  final String? maaleskalatypeEnum;
  final String? maaleskalatypeNavn;
  final String? enhetEnum;
  final String? enhetNavn;
  final List<VariableStep> trinn;

  const VariableScale({
    this.maaleskalaNavn,
    this.maaleskalatypeEnum,
    this.maaleskalatypeNavn,
    this.enhetEnum,
    this.enhetNavn,
    required this.trinn,
  });

  String get displayTitle {
    final name = maaleskalaNavn ?? maaleskalatypeEnum;
    if (name == null || name.isEmpty) return 'Måleskala';
    return 'Måleskala $name';
  }

  String? get displaySubtitle {
    final parts = <String>[];
    if (maaleskalatypeNavn != null && maaleskalatypeNavn!.isNotEmpty) {
      parts.add(maaleskalatypeNavn!);
    }
    if (enhetNavn != null && enhetNavn!.isNotEmpty) {
      parts.add(enhetNavn!);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  factory VariableScale.fromJson(Map<String, dynamic> json) {
    final rawTrinn = json['trinn'];
    final trinn = <VariableStep>[];
    if (rawTrinn is List) {
      for (final item in rawTrinn) {
        if (item is Map<String, dynamic>) {
          trinn.add(VariableStep.fromJson(item));
        } else if (item is Map) {
          trinn.add(VariableStep.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return VariableScale(
      maaleskalaNavn: json['maaleskalaNavn']?.toString(),
      maaleskalatypeEnum: json['maaleskalatypeEnum']?.toString(),
      maaleskalatypeNavn: json['maaleskalatypeNavn']?.toString(),
      enhetEnum: json['enhetEnum']?.toString(),
      enhetNavn: json['enhetNavn']?.toString(),
      trinn: trinn,
    );
  }
}

/// Parses `steps_json` into scale groups.
///
/// - Grouped format: `[{maaleskalaNavn, trinn: [...]}, ...]`
/// - Legacy flat format: `[{verdi, navn, kode}, ...]` → one anonymous scale
List<VariableScale> parseVariableSteps(dynamic decoded) {
  if (decoded is! List || decoded.isEmpty) return const [];

  final first = decoded.first;
  if (first is Map && first.containsKey('trinn')) {
    return decoded
        .whereType<Object?>()
        .map((item) {
          if (item is Map<String, dynamic>) return VariableScale.fromJson(item);
          if (item is Map) {
            return VariableScale.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<VariableScale>()
        .where((scale) => scale.trinn.isNotEmpty)
        .toList();
  }

  // Legacy flat list — keep as a single untitled group so UI still renders.
  final flat = <VariableStep>[];
  for (final item in decoded) {
    if (item is Map<String, dynamic>) {
      flat.add(VariableStep.fromJson(item));
    } else if (item is Map) {
      flat.add(VariableStep.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  if (flat.isEmpty) return const [];
  return [VariableScale(trinn: flat)];
}

/// True when [decoded] is a flat trinn list (pre-grouping scrape bug symptom).
/// Multi-scale variables incorrectly serialized this way lose scale identity.
bool isUndifferentiatedFlatSteps(dynamic decoded) {
  if (decoded is! List || decoded.isEmpty) return false;
  final first = decoded.first;
  if (first is! Map) return false;
  if (first.containsKey('trinn')) return false;
  return first.containsKey('verdi') || first.containsKey('navn');
}
