import 'package:flutter/foundation.dart';

/// Text normalization utilities for multilingual search and matching.
/// 
/// Handles French accents, Arabic diacritics, and transliteration
/// to enable flexible matching across multiple languages.
class TextNormalizer {
  /// Normalizes text for comparison: lowercase, removes accents,
  /// strips Arabic diacritics, transliterates Arabic to Latin, collapses whitespace.
  static String normalize(String input) {
    var text = input.toLowerCase().trim();

    // French accents
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'œ': 'oe',
    };
    accents.forEach((k, v) => text = text.replaceAll(k, v));

    // Arabic diacritics (tashkeel)
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Arabic-to-Latin transliteration for common place names
    const arabicToLatin = {
      'مدينة': 'medina',
      'جديدة': 'jdida',
      'جديد': 'jdida',
      'المدينة الجديدة': 'medina jdida',
      'حي': 'hay',
      'ثامر': 'thameur',
      'مرناق': 'mornag',
      'الكرم': 'elkarm',
      'الزهور': 'zelhour',
      'سيدي': 'sidi',
      'بوسالم': 'bousalem',
      'المنيهلة': 'meniehla',
      'الشراردة': 'chararda',
      'الكبار': 'kabbar',
      'النصر': 'nasser',
      'الحبيب': 'habib',
      'الطيب': 'taieb',
      'سوسة': 'sousse',
      'صفاقس': 'sfax',
      'قابس': 'gabes',
      'قفصة': 'gafsa',
      'جندوبة': 'jendouba',
      'باجة': 'beja',
      'زغوان': 'zaghwan',
      'سليانة': 'siliana',
      'الكاف': 'kef',
      'توزر': 'tozeur',
      'تطاوين': 'tataouine',
      'مدنين': 'medenine',
      'بنزرت': 'bizerte',
      'نابل': 'nabeul',
      'أريانة': 'ariana',
      'منوبة': 'manouba',
      'بن عروس': 'ben arous',
      'المهدية': 'mahdia',
      'المنستير': 'monastir',
      'القيروان': 'kairouan',
      'سيدي بوزيد': 'sidi bouzid',
      'القصرين': 'kasserine',
      'قبلي': 'kebili',
      'قرطاج': 'carthage',
      'تونس': 'tunis',
      'محطة': 'gare',
      'شارع': 'rue',
      'طريق': 'route',
      'كورسو': 'corso',
      'البنك': 'bank',
      'السوق': 'souk',
      'الحمام': 'hammam',
      'الجمهورية': 'jumhuriya',
      'الثورة': 'thawra',
      'المحطة': 'mahatta',
    };

    // Apply transliterations
    arabicToLatin.forEach((k, v) => text = text.replaceAll(k, v));

    // Normalize common abbreviations
    text = text
        .replaceAll('cité', 'cite')
        .replaceAll('cit.', 'cite')
        .replaceAll('carthage', 'carthage')
        .replaceAll('carthago', 'carthage')
        .replaceAll('nouvelle', 'nouvelle')
        .replaceAll('nouvelle medina', 'medina jdida')
        .replaceAll('madina jdida', 'medina jdida')
        .replaceAll('medina jedida', 'medina jdida')
        .replaceAll('10 décembre', '10 decembre')
        .replaceAll('10-décembre', '10 decembre')
        .replaceAll('10décembre', '10 decembre');

    // Collapse whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  /// Calculates Levenshtein distance between two strings for fuzzy matching.
  /// 
  /// Returns a value between 0 and 1, where:
  /// - 1.0 = exact match
  /// - 0.0 = completely different
  static double similarity(String s1, String s2) {
    final n1 = normalize(s1);
    final n2 = normalize(s2);
    
    if (n1 == n2) return 1.0;
    if (n1.isEmpty || n2.isEmpty) return 0.0;
    
    final distance = _levenshteinDistance(n1, n2);
    final maxLength = (n1.length > n2.length) ? n1.length : n2.length;
    return 1.0 - (distance / maxLength);
  }

  /// Computes Levenshtein distance (edit distance) between two strings.
  static int _levenshteinDistance(String s1, String s2) {
    final List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List<int>.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Checks if [query] matches [target] with the given [threshold].
  /// 
  /// A match is considered:
  /// 1. Exact match (normalized strings are equal)
  /// 2. Substring match (target contains query)
  /// 3. Similarity match (fuzzy matching above threshold)
  static bool matches(
    String query,
    String target, {
    double threshold = 0.7,
  }) {
    final q = normalize(query);
    final t = normalize(target);

    if (q.isEmpty) return true;
    if (t.isEmpty) return false;

    // Exact match
    if (q == t) return true;

    // Substring match
    if (t.contains(q)) return true;

    // Token match: check if any token matches
    final queryTokens = q.split(' ').where((s) => s.length > 1).toList();
    final targetTokens = t.split(' ').where((s) => s.length > 1).toList();

    for (final qt in queryTokens) {
      for (final tt in targetTokens) {
        if (tt.contains(qt) || similarity(qt, tt) > 0.8) {
          return true;
        }
      }
    }

    // Fuzzy matching
    return similarity(q, t) > threshold;
  }

  /// Filters a list of items by matching a query against multiple fields.
  /// 
  /// Example:
  /// ```dart
  /// final lines = filterItems<BusService>(
  ///   services,
  ///   'Carthage',
  ///   extractors: [
  ///     (s) => s.directionAr,
  ///     (s) => s.destinationNameFr,
  ///   ],
  /// );
  /// ```
  static List<T> filterItems<T>(
    List<T> items,
    String query, {
    required List<String Function(T)> extractors,
    double threshold = 0.7,
  }) {
    if (query.trim().isEmpty) return items;

    final q = normalize(query);
    final matches = <(T item, double score)>[];

    for (final item in items) {
      double maxScore = 0;
      for (final extractor in extractors) {
        final fieldValue = extractor(item);
        if (_computeMatchScore(q, normalize(fieldValue), threshold) > maxScore) {
          maxScore = _computeMatchScore(q, normalize(fieldValue), threshold);
        }
      }

      if (maxScore > 0) {
        matches.add((item, maxScore));
      }
    }

    // Sort by score (highest first)
    matches.sort((a, b) => b.$2.compareTo(a.$2));
    return matches.map((m) => m.$1).toList();
  }

  /// Computes a match score between query and target.
  /// Returns 0 if no match, value between 0 and 1 otherwise.
  static double _computeMatchScore(String query, String target, double threshold) {
    if (query.isEmpty) return 1.0;
    if (target.isEmpty) return 0.0;

    // Exact match
    if (query == target) return 1.0;

    // Starts with query
    if (target.startsWith(query)) return 0.95;

    // Contains query
    if (target.contains(query)) return 0.85;

    // Token match
    final queryTokens = query.split(' ').where((s) => s.length > 1).toList();
    final targetTokens = target.split(' ').where((s) => s.length > 1).toList();

    int matched = 0;
    for (final qt in queryTokens) {
      if (targetTokens.any((tt) => tt.contains(qt) || qt.contains(tt))) {
        matched++;
      }
    }

    if (queryTokens.isNotEmpty) {
      final tokenScore = matched / queryTokens.length;
      if (tokenScore >= 0.3) return 0.5 + tokenScore * 0.3;
    }

    // Fuzzy matching
    final score = similarity(query, target);
    return score > threshold ? score : 0;
  }

  /// Debug helper to print normalization results.
  static void debugNormalization(String input) {
    if (kDebugMode) {
      final normalized = normalize(input);
      debugPrint('[TextNormalizer] "$input" → "$normalized"');
    }
  }
}
