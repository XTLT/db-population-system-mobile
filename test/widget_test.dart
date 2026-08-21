// Flutter widget test for population_mobile app.
//
// Tests verify basic app structure and initialization.

import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/utils/validators.dart';

void main() {
  group('App Tests', () {
    test('Validators should work correctly', () {
      expect(Validators.validateIdCard(''), '身份证号不能为空');
      expect(Validators.validateName(''), '姓名不能为空');
      expect(Validators.validatePhone(''), null);
    });

    test('Name validation', () {
      expect(Validators.validateName('张三'), null);
      expect(Validators.validateName('LiMing'), null);
    });

    test('Phone validation', () {
      expect(Validators.validatePhone('13800138000'), null);
      expect(Validators.validatePhone('010-12345678'), null);
    });

    test('Land area validation', () {
      expect(Validators.validateLandArea('10.5'), null);
      expect(Validators.validateLandArea('abc'), '土地面积必须是数字');
    });
  });
}
