import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../api/person_api.dart';
import '../models/person.dart';

/// 全部人员离线数据：整包下载到应用文档目录，断网时按姓名/身份证/户号/电话查询。
///
/// 只存服务端 `/api/persons/lookup-all` 的原始字段（全部人员、全部字段）。
/// 数据量可达数 MB，因此不用 SharedPreferences，落 JSON 文件 + 内存缓存。
class PersonOfflineStore {
  PersonOfflineStore._();

  static final PersonOfflineStore instance = PersonOfflineStore._();

  static const int _formatVersion = 1;
  static const int _searchLimit = 300;

  List<Map<String, dynamic>>? _memory;
  DateTime? _savedAt;

  Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${dir.path}/offline');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return File('${offlineDir.path}/persons_all.json');
  }

  /// 读取人数/时间/体积；首次读取时解析一次大 JSON 并缓存到内存，后续直接复用。
  Future<OfflinePersonInfo> info() async {
    if (_memory != null) {
      final file = await _dataFile();
      final size = await file.exists() ? await file.length() : 0;
      return OfflinePersonInfo(
        count: _memory!.length,
        savedAt: _savedAt,
        bytes: size,
      );
    }
    final file = await _dataFile();
    if (!await file.exists()) return OfflinePersonInfo.empty();
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final rawPersons = (data['persons'] as List?) ?? const [];
      final persons = rawPersons
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _memory = persons;
      _savedAt = DateTime.tryParse(data['saved_at']?.toString() ?? '');
      return OfflinePersonInfo(
        count: persons.length,
        savedAt: _savedAt,
        bytes: await file.length(),
      );
    } catch (_) {
      return OfflinePersonInfo.empty();
    }
  }

  /// 下载/更新全部人员数据。成功后自动刷新内存缓存。
  Future<OfflinePersonInfo> downloadAll() async {
    final persons = await PersonApi.fetchAllPersons();
    final file = await _dataFile();
    final payload = jsonEncode({
      'version': _formatVersion,
      'saved_at': DateTime.now().toIso8601String(),
      'count': persons.length,
      'persons': persons,
    });
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(file.path);
    _memory = persons;
    _savedAt = DateTime.now();
    final size = await file.length();
    return OfflinePersonInfo(
      count: persons.length,
      savedAt: _savedAt,
      bytes: size,
    );
  }

  Future<void> clear() async {
    _memory = null;
    _savedAt = null;
    final file = await _dataFile();
    if (await file.exists()) await file.delete();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (_memory != null) return _memory!;
    final file = await _dataFile();
    if (!await file.exists()) return const [];
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = (data['persons'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _memory = list;
      _savedAt = DateTime.tryParse(data['saved_at']?.toString() ?? '');
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// 离线查询。输入可以是姓名（模糊）、身份证/户号/电话（精确或后几位）。
  Future<List<Person>> search(String input) async {
    final persons = await _load();
    if (persons.isEmpty) return [];
    final hits = filterPersons(persons, input, limit: _searchLimit);
    return hits.map((e) => Person.fromJson(e)).toList();
  }

  DateTime? get lastSavedAt => _savedAt;

  /// 纯函数，便于单测：不依赖文件系统与网络。
  static List<Map<String, dynamic>> filterPersons(
    List<Map<String, dynamic>> persons,
    String input, {
    int limit = _searchLimit,
  }) {
    final q = input.trim();
    if (q.isEmpty) return const [];
    final upper = q.toUpperCase();
    final lower = q.toLowerCase();

    String text(Map<String, dynamic> p, String key) =>
        (p[key] ?? '').toString().trim();

    bool exact(Map<String, dynamic> p) {
      final id = text(p, 'id_card').toUpperCase();
      final phone = text(p, 'phone');
      final huHao = text(p, 'hu_hao');
      return id == upper || phone == q || huHao == q;
    }

    bool fuzzy(Map<String, dynamic> p) {
      bool has(String key) {
        final v = text(p, key);
        if (v.isEmpty) return false;
        return v.toLowerCase().contains(lower) ||
            v.toUpperCase().contains(upper);
      }

      if (has('name')) return true;
      if (has('phone')) return true;
      if (has('hu_hao')) return true;
      if (has('id_card')) return true;
      if (has('address')) return true;
      if (has('group_name')) return true;
      return false;
    }

    final exactHits = <Map<String, dynamic>>[];
    final fuzzyHits = <Map<String, dynamic>>[];
    for (final p in persons) {
      if (exact(p)) {
        exactHits.add(p);
      } else if (fuzzy(p)) {
        fuzzyHits.add(p);
      }
      if (exactHits.length >= limit) break;
    }
    return [...exactHits, ...fuzzyHits].take(limit).toList();
  }
}

class OfflinePersonInfo {
  final int count;
  final DateTime? savedAt;
  final int bytes;

  const OfflinePersonInfo({
    required this.count,
    required this.savedAt,
    required this.bytes,
  });

  const OfflinePersonInfo.empty()
      : count = 0,
        savedAt = null,
        bytes = 0;

  bool get isEmpty => count <= 0;
}
