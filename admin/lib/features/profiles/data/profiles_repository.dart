import 'package:algoliasearch/algoliasearch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'height_converter.dart';
import 'profile_edit_input.dart';
import 'profile_form_options_cache.dart';

/// One page of matrimonial profiles from Algolia (`users_index`).
class ProfilesPageResult {
  const ProfilesPageResult({
    required this.profiles,
    required this.page,
    required this.totalHits,
    required this.totalPages,
    required this.hasMore,
  });

  final List<Map<String, dynamic>> profiles;
  final int page;
  final int totalHits;
  final int totalPages;
  final bool hasMore;
}

/// Algolia listing + Firestore read/write for `profiles/{id}`.
class ProfilesRepository {
  ProfilesRepository(this._firestore, this._formOptionsCache);

  final FirebaseFirestore _firestore;
  final ProfileFormOptionsCache _formOptionsCache;

  static const int defaultPageSize = 10;

  static const String _applicationId = 'FAU9NYCABZ';
  static const String _searchApiKey = '85245b1373fe7ab9e3c3bbb68117376b';
  static const String _primaryIndexName = 'users_index';
  /// Replica sorted by `created` descending (browse / newest first).
  static const String _newestFirstIndexName = 'users_index_created_desc';

  static const List<String> _attributesToRetrieve = [
    'objectID',
    'original_id',
    'first_name',
    'middle_name',
    'last_name',
    'full_name',
    'gender',
    'type',
    'branch',
    'education',
    'job',
    'height',
    'height_cm',
    'active',
    'is_verified',
    'is_from_book',
    'birth_date',
    'created',
    'modified',
    'images',
    'path',
  ];

  static SearchClient? _client;

  SearchClient get _searchClient {
    _client ??= SearchClient(
      appId: _applicationId,
      apiKey: _searchApiKey,
      options: const ClientOptions(
        connectTimeout: Duration(seconds: 30),
        readTimeout: Duration(seconds: 30),
      ),
    );
    return _client!;
  }

  /// Lists profiles from Algolia. [query] `*` browses newest-first; text uses the primary index for relevance.
  Future<ProfilesPageResult> fetchPage({
    int page = 0,
    int pageSize = defaultPageSize,
    String query = '*',
  }) async {
    final q = query.trim().isEmpty ? '*' : query.trim();
    final isBrowse = q == '*';
    final searchResponse = await _searchClient.search(
      searchMethodParams: SearchMethodParams(
        requests: [
          SearchForHits(
            indexName: isBrowse ? _newestFirstIndexName : _primaryIndexName,
            query: q,
            page: page,
            hitsPerPage: pageSize,
            attributesToRetrieve: _attributesToRetrieve,
          ),
        ],
      ),
    );

    final result = searchResponse.results.first;
    final hits = (result['hits'] as List<dynamic>? ?? const []);
    final nbHits = result['nbHits'] as int? ?? 0;
    final nbPages = result['nbPages'] as int? ?? 0;
    final currentPage = result['page'] as int? ?? page;

    final profiles = hits.map(_hitToRow).whereType<Map<String, dynamic>>().toList();

    return ProfilesPageResult(
      profiles: profiles,
      page: currentPage,
      totalHits: nbHits,
      totalPages: nbPages,
      hasMore: currentPage + 1 < nbPages,
    );
  }

  static Map<String, dynamic>? _hitToRow(dynamic raw) {
    if (raw is! Map) return null;
    final hit = Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    );
    final id = hit['objectID'] ?? hit['objectId'];
    if (id == null) return null;
    hit['id'] = id.toString();
    return hit;
  }

  Future<void> ensureFormOptionsLoaded() => _formOptionsCache.ensureLoaded();

  ProfileFormOptionsCache get formOptionsCache => _formOptionsCache;

  /// Loads the canonical profile document from Firestore (not Algolia).
  Future<Map<String, dynamic>> fetchProfileDocument(String profileId) async {
    final snap = await _firestore.collection('profiles').doc(profileId).get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Profile $profileId not found in Firestore.');
    }
    final data = Map<String, dynamic>.from(snap.data()!);
    data['id'] = snap.id;
    return data;
  }

  /// Updates profile fields; Algolia sync is handled by your backend/extension.
  Future<void> updateProfile({
    required String profileId,
    required ProfileEditInput input,
  }) async {
    final first = input.firstName.trim();
    final last = input.lastName.trim();
    if (first.isEmpty) {
      throw ArgumentError('First name is required');
    }

    final middle = input.middleName?.trim();
    final fullName = [
      first,
      if (middle != null && middle.isNotEmpty) middle,
      if (last.isNotEmpty) last,
    ].join(' ');

    final update = <String, dynamic>{
      'first_name': first,
      'last_name': last,
      'full_name': fullName,
      'active': input.active,
      'is_verified': input.isVerified,
      'modified': FieldValue.serverTimestamp(),
      'gender': input.gender,
      'type': input.type,
      'height': HeightConverter.formatFeetInches(
        input.heightFeet,
        input.heightInches,
      ),
      'height_feet': input.heightFeet,
      'height_inches': input.heightInches,
      'height_cm': HeightConverter.feetInchesToCm(
        input.heightFeet,
        input.heightInches,
      ),
    };

    void setOptionalString(String key, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) {
        update[key] = FieldValue.delete();
      } else {
        update[key] = v;
      }
    }

    if (middle != null && middle.isNotEmpty) {
      update['middle_name'] = middle;
    } else {
      update['middle_name'] = FieldValue.delete();
    }

    setOptionalString('original_id', input.originalId);
    setOptionalString('branch', input.branch);
    setOptionalString('education', input.education);
    setOptionalString('job', input.job);

    if (input.birthDate != null) {
      update['birth_date'] = input.birthDate!.toIso8601String();
    } else {
      update['birth_date'] = FieldValue.delete();
    }

    await _firestore.collection('profiles').doc(profileId).update(update);
  }

  /// Resolves feet/inches from profile document fields.
  static ({int feet, int inches}) parseHeight(Map<String, dynamic> data) {
    final feetRaw = data['height_feet'];
    final inchesRaw = data['height_inches'];
    if (feetRaw is num) {
      return (
        feet: feetRaw.toInt(),
        inches: inchesRaw is num ? inchesRaw.toInt() : 0,
      );
    }
    final cm = data['height_cm'];
    if (cm is num) {
      final fi = HeightConverter.cmToFeetInches(cm.toInt());
      return (feet: fi['feet']!, inches: fi['inches']!);
    }
    return (feet: 5, inches: 0);
  }

  static String normalizeGender(dynamic v) {
    final s = v?.toString().trim().toLowerCase() ?? '';
    if (s == 'male' || s == 'female') return s;
    if (s.startsWith('m')) return 'male';
    if (s.startsWith('f')) return 'female';
    return 'male';
  }

  static String normalizeMarriageType(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s == 'First Marriage' || s == 'Remarriage') return s;
    if (s.toLowerCase().contains('remarriage')) return 'Remarriage';
    return 'First Marriage';
  }

  /// Parses Firestore / Algolia date values for form fields.
  static DateTime? parseBirthDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is num) {
      final n = v.toInt();
      final ms = n < 1000000000000 ? n * 1000 : n;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    return null;
  }
}
