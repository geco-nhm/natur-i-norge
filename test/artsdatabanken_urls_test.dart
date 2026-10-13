import 'package:flutter_test/flutter_test.dart';
import 'package:naturinorge_guide/src/utils/artsdatabanken_urls.dart';

void main() {
  group('hasDeepLinkPage', () {
    test('accepts leaf-style NiN- prefix', () {
      expect(
        ArtsdatabankenUrls.hasDeepLinkPage('NiN-3.0-V-B-N-NO-GE-TG-AA-W'),
        isTrue,
      );
    });

    test('rejects top-level NIN- prefix', () {
      expect(ArtsdatabankenUrls.hasDeepLinkPage('NIN-3.0-V-B-N'), isFalse);
    });

    test('rejects null and empty', () {
      expect(ArtsdatabankenUrls.hasDeepLinkPage(null), isFalse);
      expect(ArtsdatabankenUrls.hasDeepLinkPage(''), isFalse);
    });
  });

  group('detailUrl', () {
    test('builds deep link for leaf langkode', () {
      expect(
        ArtsdatabankenUrls.detailUrl('NiN-3.0-V-B-N-NO-GE-TG-AA-W'),
        Uri.parse(
          '${ArtsdatabankenUrls.baseUrl}/NiN-3.0-V-B-N-NO-GE-TG-AA-W',
        ),
      );
    });

    test('returns null for category-root NIN- langkode', () {
      expect(ArtsdatabankenUrls.detailUrl('NIN-3.0-V-B-N'), isNull);
    });
  });

  group('variableUrl', () {
    test('deep-links leaf variables', () {
      expect(
        ArtsdatabankenUrls.variableUrl(
          langkode: 'NiN-3.0-V-B-N-NO-GE-TG-AA-W',
          parentId: 'B-N',
        ),
        Uri.parse(
          '${ArtsdatabankenUrls.baseUrl}/NiN-3.0-V-B-N-NO-GE-TG-AA-W',
        ),
      );
    });

    test('falls back to variables overview for top-level roots', () {
      for (final code in ['NIN-3.0-V-A-M', 'NIN-3.0-V-A-N', 'NIN-3.0-V-B-M', 'NIN-3.0-V-B-N']) {
        expect(
          ArtsdatabankenUrls.variableUrl(langkode: code, parentId: null),
          Uri.parse(ArtsdatabankenUrls.variablesOverviewUrl),
        );
        expect(
          ArtsdatabankenUrls.variableUrl(langkode: code, parentId: ''),
          Uri.parse(ArtsdatabankenUrls.variablesOverviewUrl),
        );
      }
    });

    test('hides link for non-root without leaf-style langkode', () {
      expect(
        ArtsdatabankenUrls.variableUrl(
          langkode: 'NIN-3.0-V-B-N',
          parentId: 'some-parent',
        ),
        isNull,
      );
    });

    test('returns null when langkode missing', () {
      expect(
        ArtsdatabankenUrls.variableUrl(langkode: null, parentId: null),
        isNull,
      );
    });
  });

  group('typeUrl', () {
    test('builds type deep link when langkode present', () {
      expect(
        ArtsdatabankenUrls.typeUrl('NiN-3.0-T-NA-T'),
        Uri.parse('${ArtsdatabankenUrls.baseUrl}/NiN-3.0-T-NA-T'),
      );
    });

    test('returns null when langkode missing', () {
      expect(ArtsdatabankenUrls.typeUrl(null), isNull);
      expect(ArtsdatabankenUrls.typeUrl(''), isNull);
    });
  });
}
