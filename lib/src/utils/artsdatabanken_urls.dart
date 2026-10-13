/// Build Artsdatabanken public web URLs for NiN types and variables.
///
/// Deep links use `https://artsdatabanken.no/naturtyper/natur-i-norge/{langkode}`.
/// Leaf variable pages use `NiN-…` casing and usually resolve. Top-level variable
/// categories store `NIN-…` langkodes that always 404 on the website.
class ArtsdatabankenUrls {
  ArtsdatabankenUrls._();

  static const baseUrl = 'https://artsdatabanken.no/naturtyper/natur-i-norge';
  static const variablesOverviewUrl =
      '$baseUrl/variabler';

  /// True when [langkode] matches the leaf-style prefix that ADB publishes pages for.
  static bool hasDeepLinkPage(String? langkode) {
    if (langkode == null || langkode.isEmpty) return false;
    return langkode.startsWith('NiN-');
  }

  /// Per-entity deep link, or null when ADB is known not to host that page.
  static Uri? detailUrl(String? langkode) {
    if (!hasDeepLinkPage(langkode)) return null;
    return Uri.parse('$baseUrl/$langkode');
  }

  /// External URL for a variable detail screen.
  ///
  /// Prefer a deep link when available. For top-level category roots (no parent),
  /// fall back to the variables overview so the browser action stays useful.
  static Uri? variableUrl({
    required String? langkode,
    required String? parentId,
  }) {
    final deep = detailUrl(langkode);
    if (deep != null) return deep;

    final isRoot = parentId == null || parentId.isEmpty;
    if (isRoot && langkode != null && langkode.isNotEmpty) {
      return Uri.parse(variablesOverviewUrl);
    }
    return null;
  }

  /// External URL for a type detail screen (types generally have working pages).
  static Uri? typeUrl(String? langkode) {
    if (langkode == null || langkode.isEmpty) return null;
    return Uri.parse('$baseUrl/$langkode');
  }
}
