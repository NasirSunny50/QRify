import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum ScanType { qrCode, barcode }
enum ActionType { scanned, generated }

class HistoryItem {
  final String id;
  final String content;
  final ScanType scanType;
  final ActionType actionType;
  final String? barcodeFormat;
  final DateTime createdAt;
  bool isFavorite;

  HistoryItem({
    required this.id,
    required this.content,
    required this.scanType,
    required this.actionType,
    this.barcodeFormat,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      content: json['content'],
      scanType: ScanType.values[json['scanType']],
      actionType: ActionType.values[json['actionType']],
      barcodeFormat: json['barcodeFormat'],
      createdAt: DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'scanType': scanType.index,
        'actionType': actionType.index,
        'barcodeFormat': barcodeFormat,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  // Detect content type for smart display
  ContentCategory get category {
    final lower = content.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ContentCategory.url;
    } else if (lower.startsWith('mailto:')) {
      return ContentCategory.email;
    } else if (lower.startsWith('tel:')) {
      return ContentCategory.phone;
    } else if (lower.startsWith('wifi:')) {
      return ContentCategory.wifi;
    } else if (lower.startsWith('begin:vcard')) {
      return ContentCategory.contact;
    } else if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return ContentCategory.sms;
    } else if (RegExp(r'^\d{8,13}$').hasMatch(content)) {
      return ContentCategory.barcode;
    }
    return ContentCategory.text;
  }

  String get displayTitle {
    switch (category) {
      case ContentCategory.url:
        try {
          final uri = Uri.parse(content);
          return uri.host;
        } catch (_) {
          return content;
        }
      case ContentCategory.email:
        return content.replaceFirst('mailto:', '');
      case ContentCategory.phone:
        return content.replaceFirst('tel:', '');
      case ContentCategory.wifi:
        final match = RegExp(r'S:([^;]+)').firstMatch(content);
        return match?.group(1) ?? content;
      case ContentCategory.contact:
        final match = RegExp(r'FN:([^\n]+)').firstMatch(content);
        return match?.group(1) ?? 'Contact';
      default:
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
    }
  }
}

enum ContentCategory { url, email, phone, wifi, contact, sms, barcode, text }

class HistoryService {
  static const _key = 'history_items';
  static final _uuid = Uuid();

  static Future<List<HistoryItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => HistoryItem.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> add({
    required String content,
    required ScanType scanType,
    required ActionType actionType,
    String? barcodeFormat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    // Deduplicate recent (same content within last hour)
    final existing = raw
        .map((e) => HistoryItem.fromJson(jsonDecode(e)))
        .where((item) =>
            item.content == content &&
            item.scanType == scanType &&
            item.actionType == actionType &&
            DateTime.now().difference(item.createdAt).inMinutes < 60)
        .isNotEmpty;

    if (existing) return;

    final item = HistoryItem(
      id: _uuid.v4(),
      content: content,
      scanType: scanType,
      actionType: actionType,
      barcodeFormat: barcodeFormat,
      createdAt: DateTime.now(),
    );

    raw.insert(0, jsonEncode(item.toJson()));

    // Keep max 200 items
    if (raw.length > 200) raw.removeRange(200, raw.length);
    await prefs.setStringList(_key, raw);
  }

  static Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = raw.map((e) => HistoryItem.fromJson(jsonDecode(e))).toList();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    items[idx].isFavorite = !items[idx].isFavorite;
    await prefs.setStringList(
        _key, items.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw
        .where((e) => HistoryItem.fromJson(jsonDecode(e)).id != id)
        .toList();
    await prefs.setStringList(_key, updated);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
