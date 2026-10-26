import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SensitiveCacheService {
  SensitiveCacheService._();

  static Future<int> clearPlaintextTemporaryFiles({
    bool includeActiveShares = true,
  }) async {
    var removed = 0;
    try {
      final cache = await getTemporaryDirectory();
      final names = [
        'hidden_photo_vault_playback',
        if (includeActiveShares) 'hidden_photo_vault_share',
      ];
      for (final name in names) {
        final directory = Directory(p.join(cache.path, name));
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          removed++;
        }
      }
    } catch (_) {
      // Privacy cleanup is best effort and must not block vault locking.
    }
    return removed;
  }
}
