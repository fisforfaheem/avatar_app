import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';

/// A service to interact with IndexedDB on the web for storing binary data.
class WebDbService {
  static const String _dbName = 'AvatarAppDB';
  static const int _dbVersion = 1;
  static const String _storeName = 'assets';

  Database? _db;

  // Private constructor
  WebDbService._();

  // Singleton instance
  static final WebDbService instance = WebDbService._();

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final idbFactory = getIdbFactory()!;
    return await idbFactory.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (e) {
        final db = e.database;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  /// Saves binary data (asset) to the database.
  Future<void> saveAsset(String key, Uint8List bytes) async {
    if (!kIsWeb) return;
    try {
      final db = await _database;
      final txn = db.transaction(_storeName, 'readwrite');
      final store = txn.objectStore(_storeName);
      await store.put(bytes, key);
      await txn.completed;
      debugPrint('[WebDbService] Saved asset with key: $key');
    } catch (e) {
      debugPrint('[WebDbService] Error saving asset $key: $e');
      rethrow;
    }
  }

  /// Loads binary data (asset) from the database.
  Future<Uint8List?> loadAsset(String key) async {
    if (!kIsWeb) return null;
    try {
      final db = await _database;
      final txn = db.transaction(_storeName, 'readonly');
      final store = txn.objectStore(_storeName);
      final value = await store.getObject(key);
      await txn.completed;
      debugPrint('[WebDbService] Loaded asset with key: $key');
      if (value is Uint8List) {
        return value;
      }
      // Handle cases where data might be stored incorrectly as List<int>
      if (value is List<int>) {
        return Uint8List.fromList(value);
      }
      return null;
    } catch (e) {
      debugPrint('[WebDbService] Error loading asset $key: $e');
      return null;
    }
  }

  /// Deletes an asset from the database.
  Future<void> deleteAsset(String key) async {
    if (!kIsWeb) return;
    try {
      final db = await _database;
      final txn = db.transaction(_storeName, 'readwrite');
      final store = txn.objectStore(_storeName);
      await store.delete(key);
      await txn.completed;
      debugPrint('[WebDbService] Deleted asset with key: $key');
    } catch (e) {
      debugPrint('[WebDbService] Error deleting asset $key: $e');
    }
  }

  /// Clears the entire asset store.
  Future<void> clearAllAssets() async {
    if (!kIsWeb) return;
    try {
      final db = await _database;
      final txn = db.transaction(_storeName, 'readwrite');
      final store = txn.objectStore(_storeName);
      await store.clear();
      await txn.completed;
      debugPrint('[WebDbService] Cleared all assets.');
    } catch (e) {
      debugPrint('[WebDbService] Error clearing assets: $e');
    }
  }
}
