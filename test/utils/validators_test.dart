import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('validateIdCard', () {
      test('should return error for empty id card', () {
        expect(Validators.validateIdCard(null), '身份证号不能为空');
        expect(Validators.validateIdCard(''), '身份证号不能为空');
      });

      test('should return error for invalid length', () {
        expect(Validators.validateIdCard('123'), '身份证号长度不正确');
        expect(Validators.validateIdCard('12345678901234'), '身份证号长度不正确');
        expect(Validators.validateIdCard('12345678901234567890'), '身份证号长度不正确');
      });

      test('should validate 18-digit id card', () {
        // 有效的18位身份证号（使用正确的校验码）
        expect(Validators.validateIdCard('11010519491231002X'), null);
        // 使用校验码计算得出的有效身份证
        expect(Validators.validateIdCard('110105199003078035'), null);
      });

      test('should return error for invalid 18-digit id card', () {
        // 校验码错误
        expect(Validators.validateIdCard('110105194912310022'), '身份证号校验不通过');
      });

      test('should validate 15-digit id card', () {
        // 有效的15位身份证号
        expect(Validators.validateIdCard('123456789012345'), null);
      });

      test('should return error for non-digit 15-digit id card', () {
        expect(Validators.validateIdCard('12345678901234A'), '身份证号格式不正确');
      });
    });

    group('validateName', () {
      test('should return error for empty name', () {
        expect(Validators.validateName(null), '姓名不能为空');
        expect(Validators.validateName(''), '姓名不能为空');
      });

      test('should return error for name too short or too long', () {
        // 单字姓名（太短）
        expect(Validators.validateName('张'), '姓名长度应为2-20个字符');
        // 超过20个字符的名字（21个字）
        final longName = '张三李四王五赵六钱七孙八周九吴十郑王一二三';
        expect(longName.length, greaterThan(20)); // 确认超过20个字符
        expect(Validators.validateName(longName), '姓名长度应为2-20个字符');
      });

      test('should return error for invalid characters', () {
        expect(Validators.validateName('张三123'), '姓名只能包含中文和字母');
        expect(Validators.validateName('Zhang San'), '姓名只能包含中文和字母');
      });

      test('should validate valid names', () {
        expect(Validators.validateName('张三'), null);
        expect(Validators.validateName('LiMing'), null);
        expect(Validators.validateName('王建国'), null);
      });
    });

    group('validatePhone', () {
      test('should return null for empty phone (optional)', () {
        expect(Validators.validatePhone(null), null);
        expect(Validators.validatePhone(''), null);
      });

      test('should validate mobile phone', () {
        expect(Validators.validatePhone('13800138000'), null);
        expect(Validators.validatePhone('15012345678'), null);
        expect(Validators.validatePhone('19912345678'), null);
      });

      test('should return error for invalid mobile phone', () {
        expect(Validators.validatePhone('12345678901'), '手机号格式不正确');
        expect(Validators.validatePhone('10012345678'), '手机号格式不正确');
      });

      test('should validate landline phone', () {
        expect(Validators.validatePhone('010-12345678'), null);
        expect(Validators.validatePhone('0755-87654321'), null);
      });

      test('should return error for invalid phone format', () {
        // 8位纯数字但没有区号，不符合固话格式
        expect(Validators.validatePhone('12345678'), '电话格式不正确');
        // 11位非数字字符，被当作手机号验证
        expect(Validators.validatePhone('abcdefghijk'), '手机号格式不正确');
        // 11位数字但不是有效手机号（第一位必须是1）
        expect(Validators.validatePhone('02345678901'), '手机号格式不正确');
      });
    });

    group('validateAddress', () {
      test('should return null for valid address', () {
        expect(Validators.validateAddress('北京市朝阳区'), null);
        expect(Validators.validateAddress('上海市浦东新区张江高科技园'), null);
      });

      test('should return error for address too long', () {
        final longAddress = 'A' * 201;
        expect(Validators.validateAddress(longAddress), '地址长度不能超过200个字符');
      });
    });

    group('validateLandArea', () {
      test('should return null for empty value', () {
        expect(Validators.validateLandArea(null), null);
        expect(Validators.validateLandArea(''), null);
      });

      test('should return error for non-numeric value', () {
        expect(Validators.validateLandArea('abc'), '土地面积必须是数字');
      });

      test('should return error for negative value', () {
        expect(Validators.validateLandArea('-10'), '土地面积不能为负数');
      });

      test('should return error for value too large', () {
        expect(Validators.validateLandArea('100000'), '土地面积数值过大');
      });

      test('should validate valid land area', () {
        expect(Validators.validateLandArea('10.5'), null);
        expect(Validators.validateLandArea('100'), null);
      });
    });

    group('validateSocialCard', () {
      test('should return null for empty value', () {
        expect(Validators.validateSocialCard(null), null);
        expect(Validators.validateSocialCard(''), null);
      });

      test('should return error for invalid characters', () {
        expect(Validators.validateSocialCard('123-456'), '社保卡号只能包含字母和数字');
        expect(Validators.validateSocialCard('abc@def'), '社保卡号只能包含字母和数字');
      });

      test('should return error for value too long', () {
        final longCard = 'A' * 31;
        expect(Validators.validateSocialCard(longCard), '社保卡号长度不能超过30个字符');
      });

      test('should validate valid social card', () {
        expect(Validators.validateSocialCard('1234567890'), null);
        expect(Validators.validateSocialCard('ABCD1234'), null);
      });
    });

    group('extractBirthday', () {
      test('should extract birthday from 18-digit id card', () {
        final birthday = Validators.extractBirthday('11010519491231002X');
        expect(birthday?.year, 1949);
        expect(birthday?.month, 12);
        expect(birthday?.day, 31);
      });

      test('should extract birthday from 15-digit id card', () {
        final birthday = Validators.extractBirthday('123456940131000');
        expect(birthday?.year, 1994);
        expect(birthday?.month, 1);
        expect(birthday?.day, 31);
      });

      test('should return null for invalid id card', () {
        expect(Validators.extractBirthday('123'), null);
      });
    });

    group('extractGender', () {
      test('should extract male gender from 18-digit id card', () {
        expect(Validators.extractGender('110105194912310011'), '男');
      });

      test('should extract female gender from 18-digit id card', () {
        expect(Validators.extractGender('110105194912310022'), '女');
      });

      test('should extract gender from 15-digit id card', () {
        expect(Validators.extractGender('123456940131001'), '男');
        expect(Validators.extractGender('123456940131002'), '女');
      });

      test('should return null for invalid id card', () {
        expect(Validators.extractGender('123'), null);
      });
    });

    group('calculateAge', () {
      test('should calculate age correctly', () {
        final now = DateTime.now();
        final birthday = DateTime(now.year - 25, now.month, now.day);
        expect(Validators.calculateAge(birthday), 25);
      });

      test('should handle birthday not yet occurred this year', () {
        final now = DateTime.now();
        final birthday = DateTime(now.year - 25, now.month + 1, now.day);
        expect(Validators.calculateAge(birthday), 24);
      });
    });
  });
}
