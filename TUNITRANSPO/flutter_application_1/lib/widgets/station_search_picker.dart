import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/station_model.dart';
import '../theme/app_theme.dart';

class StationSearchPicker extends StatefulWidget {
  final String label;
  final Station? initialValue;
  final ValueChanged<Station> onSelected;
  final FirebaseFirestore? firestore;

  const StationSearchPicker({
    super.key,
    required this.label,
    required this.onSelected,
    this.initialValue,
    this.firestore,
  });

  @override
  State<StationSearchPicker> createState() => _StationSearchPickerState();
}

class _StationSearchPickerState extends State<StationSearchPicker> {
  static const int _maxSearchResults = 8;
  static const int _nearbyLimit = 5;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  late final FirebaseFirestore _firestore;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  Timer? _debounce;
  bool _isLoadingSearch = false;
  bool _isLoadingNearby = false;

  String _query = '';

  List<_StationSearchItem> _searchResults = const <_StationSearchItem>[];
  List<_StationSearchItem> _nearbyStations = const <_StationSearchItem>[];
  List<_StationSearchItem> _allStations = const <_StationSearchItem>[];

  // ── Static alias map (mirrors StationRepository._stationAliasesById) ──────
  static const Map<String, List<String>> _stationAliases = {
    'bs_tunis_ville': ['tunis', 'gare de tunis', 'tunis gare', 'tunis centrale'],
    'bs_ezzahra': ['ez zahra', 'ez-zahra', 'ezzahra banlieue'],
    'bs_hammam_echatt': ['hammam chott', 'hammam echatt'],
    'bs_megrine': ['megrine', 'megrine'],
    'ms_aeroport': ['aeroport', 'airport', 'aeroport skanes monastir'],
    'ms_sousse_zi': ['sousse zi', 'sousse zone industrielle'],
    'ms_monastir_zi': ['monastir zi', 'monastir zone industrielle'],
    'bn_tunis': ['tunis', 'tunis banlieue', 'gare de tunis'],
    'bn_hammamet': ['hammamet', 'hammament', 'hammamet banlieue'],
    'sncft_sousse_voyageurs': ['sousse', 'sousse gare', 'gare de sousse'],
    'sncft_sfax': ['sfax gare', 'gare de sfax'],
    'sncft_gabes': ['gabes gare', 'gare de gabes'],
    // TRANSTU hubs
    'transtu_hub_tunis_marine': ['tunis marine', 'marine', 'bus tunis'],
    'transtu_hub_barcelone': ['barcelone', 'place barcelone'],
    'transtu_hub_jardin_thameur': ['jardin thameur', 'thameur', 'hadika thameur'],
    'transtu_hub_bab_alioua': ['bab alioua', 'bab aliwa'],
    'transtu_hub_ariana': ['ariana', 'ariana bus'],
    'transtu_hub_carthage': ['carthage', 'carthage bus'],
    'transtu_hub_charguia': ['charguia', 'charguia bus', 'el charguia', 'la charguia'],
    'transtu_hub_intilaka': ['intilaka', 'intileka', 'intilaqa'],
    'transtu_hub_bellevie': ['bellevue', 'bellevie', 'belle vue'],
    'transtu_hub_khaireddine': [
      'kheireddine',
      'khaireddine',
      'khaireddin',
      'kheredine',
      'خير الدين',
    ],
    'transtu_hub_montazah': ['montazah', 'montazeh'],
    'transtu_hub_morneg': ['mornag', 'morneg'],
    'transtu_hub_10_decembre': [
      '10 decembre',
      'dix decembre',
      '10 december',
      '10 ديسمبر',
    ],
    'transtu_hub_slimlen_kahia': ['slimane kahia', 'slim kahia', 'slimlen kahia'],
    'transtu_hub_tbourba': ['tebourba', 'tbourba'],
  };

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    // Show the localized name in the text field for the initial value.
    _controller = TextEditingController(
      text: widget.initialValue != null
          ? widget.initialValue!.localizedName(
              WidgetsBinding.instance.platformDispatcher.locale.languageCode,
            )
          : '',
    );
    _focusNode = FocusNode();

    _query = _controller.text.trim();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final stations = await _fetchStationsFromFirestore();
    if (!mounted) return;
    _allStations = stations;

    if (_query.length >= 2) {
      _runSearch(_query);
    } else {
      _loadNearbyStations();
    }
  }

  Future<List<_StationSearchItem>> _fetchStationsFromFirestore() async {
    final snapshot = await _firestore.collection('stations').limit(500).get();
    return snapshot.docs
        .map((doc) => _StationSearchItem.fromDoc(doc))
        .where((item) => item.station.name.trim().isNotEmpty)
        .toList();
  }

  void _onQueryChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();

    if (_query.length < 2) {
      setState(() {
        _searchResults = const <_StationSearchItem>[];
      });
      _loadNearbyStations();
      return;
    }

    _debounce = Timer(_debounceDelay, () {
      _runSearch(_query);
    });
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = _normalize(rawQuery);
    if (query.length < 2) return;

    setState(() {
      _isLoadingSearch = true;
    });

    final source = await _fetchStationsFromFirestore();
    _allStations = source;

    final matches = <_ScoredStation>[];
    for (final item in source) {
      final score = _scoreMatch(item, query);
      if (score > 0) {
        matches.add(_ScoredStation(item: item, score: score));
      }
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.item.station.name.compareTo(b.item.station.name);
    });

    if (!mounted || _query.trim() != rawQuery.trim()) return;

    setState(() {
      _isLoadingSearch = false;
      _searchResults =
          matches.take(_maxSearchResults).map((m) => m.item).toList();
    });
  }

  /// Returns a list of known aliases for [stationId].
  List<String> _aliasesFor(String stationId) {
    return _stationAliases[stationId] ?? const [];
  }

  double _scoreMatch(_StationSearchItem item, String query) {
    final fields = <String>[
      _normalize(item.station.name),
      _normalize(item.nameAr ?? ''),
      _normalize(item.nameEn ?? ''),
    ].where((f) => f.isNotEmpty).toList();

    // Add static aliases for this station.
    final aliases = _aliasesFor(item.station.id);
    fields.addAll(aliases.map(_normalize));

    var score = 0.0;
    for (final field in fields) {
      if (field == query) {
        score = score < 1.0 ? 1.0 : score;
      } else if (field.startsWith(query)) {
        score = score < 0.9 ? 0.9 : score;
      } else if (field.contains(query)) {
        score = score < 0.75 ? 0.75 : score;
      } else {
        // Token-overlap fallback: at least half the query tokens appear in field.
        final qTokens =
            query.split(' ').where((t) => t.length > 1).toList();
        final fTokens = field.split(' ');
        if (qTokens.isNotEmpty) {
          final matched = qTokens
              .where((qt) => fTokens.any((ft) => ft.startsWith(qt)))
              .length;
          final ratio = matched / qTokens.length;
          if (ratio >= 0.5) {
            final tokenScore = 0.5 + ratio * 0.2;
            score = score < tokenScore ? tokenScore : score;
          }
        }
      }
    }

    return score;
  }

  Future<void> _loadNearbyStations() async {
    if (_query.length >= 2) return;

    setState(() {
      _isLoadingNearby = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _nearbyStations = const <_StationSearchItem>[];
          _isLoadingNearby = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _nearbyStations = const <_StationSearchItem>[];
          _isLoadingNearby = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      List<_StationSearchItem> source = _allStations;
      if (source.isEmpty) {
        source = await _fetchStationsFromFirestore();
        _allStations = source;
      }

      final ranked = source
          .map(
            (item) => _NearbyDistance(
              item: item,
              distanceMeters: Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                item.station.latitude,
                item.station.longitude,
              ),
            ),
          )
          .toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      if (!mounted || _query.length >= 2) return;

      setState(() {
        _nearbyStations =
            ranked.take(_nearbyLimit).map((e) => e.item).toList();
        _isLoadingNearby = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyStations = const <_StationSearchItem>[];
        _isLoadingNearby = false;
      });
    }
  }

  String _normalize(String value) {
    var text = value.toLowerCase().trim();

    const replacements = <String, String>{
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ñ': 'n',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
      'œ': 'oe', 'æ': 'ae',
      '\u2018': "'", '\u2019': "'", '`': "'",
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    text = text.replaceAll(RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    text = text.replaceAll(RegExp('[^\u0600-\u06FFa-z0-9\\s\']'), ' ');
    text = text.replaceAll(RegExp('\\s+'), ' ');

    return text.trim();
  }

  Color _lineColor(Station station) {
    final operators = station.operatorsHere;
    final isMetroSahel = operators.contains('sncft_sahel');
    final isBanlieue =
        operators.any((op) => op.startsWith('sncft_banlieue_'));
    final isGrandesLignes = operators.contains('sncft_grandes_lignes') ||
        station.id.startsWith('sncft_');

    if (isMetroSahel) return AppTheme.primaryTealBrand;
    if (isBanlieue) return const Color(0xFF1E88E5);
    if (isGrandesLignes) return const Color(0xFFFB8C00);
    return AppTheme.mediumGrey;
  }

  String _lineLabel(Station station) {
    final operators = station.operatorsHere;
    if (operators.contains('sncft_sahel')) return 'Metro Sahel';
    if (operators.any((op) => op.startsWith('sncft_banlieue_'))) {
      return 'Banlieue';
    }
    if (operators.contains('sncft_grandes_lignes') ||
        station.id.startsWith('sncft_')) {
      return 'Grandes Lignes';
    }
    return 'Transport';
  }

  void _selectStation(_StationSearchItem item) {
    final lang = Localizations.localeOf(context).languageCode;
    _controller.text = item.station.localizedName(lang);
    widget.onSelected(item.station);
    _focusNode.unfocus();
  }

  Widget _buildResultTile(_StationSearchItem item) {
    final color = _lineColor(item.station);
    final cityLabel = item.cityLabel.isNotEmpty ? item.cityLabel : '-';
    final lang = Localizations.localeOf(context).languageCode;

    return ListTile(
      onTap: () => _selectStation(item),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        item.station.localizedName(lang),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((item.nameAr ?? '').trim().isNotEmpty)
            Text(
              item.nameAr!,
              textDirection: TextDirection.rtl,
            ),
          const SizedBox(height: 2),
          Text(
            _lineLabel(item.station),
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
          ),
        ],
      ),
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          cityLabel,
          style: const TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
    );
  }

  Widget _buildResultsPanel() {
    if (_query.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Stations proches',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isLoadingNearby)
            const LinearProgressIndicator(minHeight: 2)
          else if (_nearbyStations.isEmpty)
            const Text(
              'Localisation indisponible',
              style: TextStyle(color: AppTheme.mediumGrey),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nearbyStations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) =>
                  _buildResultTile(_nearbyStations[index]),
            ),
        ],
      );
    }

    if (_isLoadingSearch) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Aucune station trouvée',
          style: TextStyle(color: AppTheme.mediumGrey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) => _buildResultTile(_searchResults[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        _buildResultsPanel(),
      ],
    );
  }
}

class _StationSearchItem {
  final Station station;
  final String? nameAr;
  final String? nameEn;
  final String cityLabel;

  const _StationSearchItem({
    required this.station,
    required this.cityLabel,
    this.nameAr,
    this.nameEn,
  });

  factory _StationSearchItem.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final cityLabel =
        (data['city'] ?? data['cityName'] ?? data['cityId'] ?? '').toString();
    final cityId = (data['cityId'] ?? data['city'] ?? '').toString();
    final latitude = (data['latitude'] ?? data['lat'] ?? 0.0) as num;
    final longitude = (data['longitude'] ?? data['lng'] ?? 0.0) as num;

    final station = Station(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      nameAr: data['nameAr']?.toString(),
      nameEn: data['nameEn']?.toString(),
      cityId: cityId,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: data['address']?.toString(),
      transportTypes:
          List<String>.from(data['transportTypes'] ?? const []),
      operatorsHere:
          List<String>.from(data['operatorsHere'] ?? const []),
      services: StationServices.fromMap(
        Map<String, dynamic>.from(
            data['services'] ?? const <String, dynamic>{}),
      ),
      isMainHub: data['isMainHub'] == true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );

    return _StationSearchItem(
      station: station,
      nameAr: data['nameAr']?.toString(),
      nameEn: data['nameEn']?.toString(),
      cityLabel: cityLabel,
    );
  }
}

class _ScoredStation {
  final _StationSearchItem item;
  final double score;

  const _ScoredStation({required this.item, required this.score});
}

class _NearbyDistance {
  final _StationSearchItem item;
  final double distanceMeters;

  const _NearbyDistance({required this.item, required this.distanceMeters});
}
