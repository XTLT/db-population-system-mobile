import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/update_service.dart';

void main() {
  // 仅覆盖纯静态方法 formatFileSize。
  // checkUpdate / downloadAndInstall / _installApk / updateServer 依赖
  // PackageInfo、path_provider、permission_handler、MethodChannel、真实 Dio 网络，
  // 且 UpdateService 构造时会持有 ApiClient().dio，单测环境不覆盖。
  group('UpdateService.formatFileSize Tests', () {
    test('B 区间', () {
      expect(UpdateService.formatFileSize(0), '0 B');
      expect(UpdateService.formatFileSize(512), '512 B');
      expect(UpdateService.formatFileSize(1023), '1023 B');
    });

    test('KB 区间（保留 1 位小数）', () {
      expect(UpdateService.formatFileSize(1024), '1.0 KB');
      expect(UpdateService.formatFileSize(1536), '1.5 KB');
      expect(UpdateService.formatFileSize(1024 * 1024 - 1), '1024.0 KB');
    });

    test('MB 区间', () {
      expect(UpdateService.formatFileSize(1024 * 1024), '1.0 MB');
      expect(UpdateService.formatFileSize(5 * 1024 * 1024), '5.0 MB');
      expect(UpdateService.formatFileSize(3 * 1024 * 1024 + 512 * 1024), '3.5 MB');
    });

    test('GB 区间', () {
      expect(UpdateService.formatFileSize(1024 * 1024 * 1024), '1.0 GB');
      expect(UpdateService.formatFileSize(2 * 1024 * 1024 * 1024), '2.0 GB');
      expect(UpdateService.formatFileSize(2 * 1024 * 1024 * 1024 + 512 * 1024 * 1024), '2.5 GB');
    });
  });

  group('UpdateInfo.fromJson Tests（纯数据类，无平台依赖）', () {
    test('应字段级解析', () {
      final info = UpdateInfo.fromJson({
        'has_update': true,
        'latest_version': '1.2.0',
        'latest_code': 12,
        'release_notes': '修复 bug',
        'download_url': 'https://x/app.apk',
        'file_size': 1024000,
        'checksum': 'abc',
        'is_external_url': false,
      });
      expect(info.hasUpdate, true);
      expect(info.latestVersion, '1.2.0');
      expect(info.latestCode, 12);
      expect(info.releaseNotes, '修复 bug');
      expect(info.downloadUrl, 'https://x/app.apk');
      expect(info.fileSize, 1024000);
      expect(info.checksum, 'abc');
      expect(info.isExternalUrl, false);
    });

    test('缺省值应正确', () {
      final info = UpdateInfo.fromJson(<String, dynamic>{});
      expect(info.hasUpdate, false);
      expect(info.latestVersion, '');
      expect(info.latestCode, 0);
      expect(info.releaseNotes, '');
      expect(info.downloadUrl, isNull);
      expect(info.fileSize, 0);
      expect(info.checksum, isNull);
      expect(info.isExternalUrl, false);
    });
  });
}
