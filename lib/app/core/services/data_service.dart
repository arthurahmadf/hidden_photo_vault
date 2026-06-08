import 'package:hidden_photo_vault/app/data/models/app_setting_model.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/auth_model.dart';
import '../models/page_log_model.dart';
import '../models/user_model.dart';

class HiveBox<T> {
  final String name;
  Box? _box;

  HiveBox(this.name);

  Future<void> init() async {
    _box = await Hive.openBox(name);
  }

  // =========================
  // SINGLE
  // =========================
  T? get data => _box?.get('data') as T?;
  set data(T? value) {
    if (value == null) {
      _box?.delete('data');
    } else {
      _box?.put('data', value);
    }
  }

  // =========================
  // LIST
  // =========================

  /// Return all items as List<T>
  List<T> get list {
    return _box?.values.cast<T>().toList() ?? [];
  }

  /// Filter all items matching [test].
  List<T> where(bool Function(T item) test) {
    return _box?.values.cast<T>().where(test).toList() ?? [];
  }

  /// Add new item to list
  Future<void> add(T value) async {
    await _box?.add(value);
  }

  /// Replace entire list
  Future<void> setList(List<T> values) async {
    await _box?.clear();
    await _box?.addAll(values);
  }

  /// Remove item by index
  Future<void> removeAt(int index) async {
    await _box?.deleteAt(index);
  }

  /// Check objkect existance
  bool exists(bool Function(T item) test) {
    return _box?.values.cast<T>().any(test) ?? false;
  }

  /// Get Object index
  int indexWhere(bool Function(T item) test) {
    if (_box == null) return -1;
    return _box!.values.cast<T>().toList().indexWhere(test);
  }

  Future<void> clear() async => _box?.clear();

  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box?.close();
      _box = null;
    }
  }

  Future<void> deleteBox() async {
    if (_box?.isOpen ?? false) {
      await _box?.close();
    }
    await Hive.deleteBoxFromDisk(name);
    _box = null;
  }

  Future<void> put(String key, T value) async {
    await _box?.put(key, value);
  }

  T? getById(String key) => _box?.get(key) as T?;

  Future<void> deleteById(String key) async {
    await _box?.delete(key);
  }

  Future<void> update(String key, T value) async {
    await _box?.put(key, value);
  }

  T? find(bool Function(T item) test) {
    try {
      return _box?.values.cast<T>().firstWhere(test, orElse: () => null as T);
    } catch (_) {
      return null;
    }
  }
}

class DataService {
  static final auth = HiveBox<Auth>('auth');
  static final user = HiveBox<User>('user');
  static final pageLog = HiveBox<PageLog>('pageLog');
  static final gallery = HiveBox<GalleryMedia>('galleryImage');
  static final vault = HiveBox<Vault>('vault');
  static final setting = HiveBox<AppSetting>('appSetting');

  // static final user = HiveBox<User>('user'); // add more as needed

  static Future<void> init() async {
    await Hive.initFlutter();

    // register adapters
    Hive.registerAdapter(AuthAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(PageLogAdapter());
    Hive.registerAdapter(GalleryMediaAdapter());
    Hive.registerAdapter(VaultAdapter());
    Hive.registerAdapter(AppSettingAdapter());

    // open boxes
    await auth.init();
    await user.init();
    await pageLog.init();
    await gallery.init();
    await vault.init();
    await setting.init();
  }

  /// Close all boxes safely
  static Future<void> closeAll() async {
    await auth.close();
    await user.close();
    await pageLog.close();
    await gallery.close();
    await vault.close();
    await setting.close();
  }

  /// Delete all boxes from disk (wipe all persisted data)
  static Future<void> deleteAll() async {
    await auth.deleteBox();
    await user.deleteBox();
    await pageLog.deleteBox();
    await gallery.deleteBox();
    await vault.deleteBox();
    await setting.deleteBox();
  }
}
