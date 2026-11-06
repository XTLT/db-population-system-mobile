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

      test('should reject 15-digit id card', () {
        // 方案二：15 位不再支持录入校验，统一要求 18 位（读老数据的 extract* 仍兼容）
        expect(Validators.validateIdCard('123456789012345'), '身份证号长度不正确');
      });

      test('should return error for non-digit 15-digit id card', () {
        // 15 位先被长度规则拦下，走不到格式校验
        expect(Validators.validateIdCard('12345678901234A'), '身份证号长度不正确');
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
        expect(Validators.validatePhone('12345678901'), '电话号码不对！');
        expect(Validators.validatePhone('10012345678'), '电话号码不对！');
      });

      test('should reject landline phone', () {
        // 业务上只录手机号，座机一律不放行
        expect(Validators.validatePhone('010-12345678'), '电话号码不对！');
        expect(Validators.validatePhone('0755-87654321'), '电话号码不对！');
        expect(Validators.validatePhone('08511234567'), '电话号码不对！');
        expect(Validators.validatePhone('0851-12345678'), '电话号码不对！');
      });

      test('should return error for invalid phone format', () {
        // 8位纯数字但没有区号，不符合固话格式
        expect(Validators.validatePhone('12345678'), '电话号码不对！');
        // 11位非数字字符
        expect(Validators.validatePhone('abcdefghijk'), '电话号码不对！');
        // 11位数字但不是有效手机号（第一位必须是1）
        expect(Validators.validatePhone('02345678901'), '电话号码不对！');
      });
    });

    // ===== 本次新增：空格清洗 + 出生日期合法性（与服务端同一口径） =====

    group('validateIdCard 空格与出生日期', () {
      // 补齐一位正确的校验位，构造"校验位一定合法"的号码，
      // 这样才能真正测到出生日期分支（否则先被校验位拦下）
      String makeId(String prefix17) {
        const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
        const codes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
        var sum = 0;
        for (var i = 0; i < 17; i++) {
          sum += int.parse(prefix17[i]) * weights[i];
        }
        return prefix17 + codes[sum % 11];
      }

      test('粘贴带空格的 18 位号码应通过', () {
        final id = makeId('52032519900101123');
        final spaced =
            '${id.substring(0, 4)} ${id.substring(4, 8)} ${id.substring(8, 12)} ${id.substring(12)}';
        expect(Validators.validateIdCard(spaced), null);
      });

      test('中间有制表符应通过', () {
        final id = makeId('52032519900101123');
        expect(
            Validators.validateIdCard('${id.substring(0, 10)}\t${id.substring(10)}'),
            null);
      });

      test('出生日期非法但校验位正确时，应报对应日期错误', () {
        expect(Validators.validateIdCard(makeId('52032519900230123')),
            '身份证号出生日期无效'); // 2 月 30 日
        expect(Validators.validateIdCard(makeId('52032519900431123')),
            '身份证号出生日期无效'); // 4 月 31 日
        expect(Validators.validateIdCard(makeId('52032519901301123')),
            '身份证号出生月份无效'); // 13 月
        expect(Validators.validateIdCard(makeId('52032519900001123')),
            '身份证号出生月份无效'); // 00 月
        expect(Validators.validateIdCard(makeId('52032518000101123')),
            '身份证号出生年份无效'); // 1800 年
        expect(Validators.validateIdCard(makeId('52032519900100123')),
            '身份证号出生日期无效'); // 0 日
      });

      test('闰年 2 月 29 日应通过，平年 2 月 29 日应拒绝', () {
        expect(Validators.validateIdCard(makeId('52032519920229123')), null);
        expect(Validators.validateIdCard(makeId('52032519900229123')),
            '身份证号出生日期无效');
      });
    });

    group('validatePhone 空格清洗', () {
      test('粘贴带空格的手机号应通过', () {
        expect(Validators.validatePhone('138 0013 8000'), null);
        expect(Validators.validatePhone(' 13800138000 '), null);
      });

      test('带横杠仍应拒绝', () {
        expect(Validators.validatePhone('138-0013-8000'), '电话号码不对！');
      });

      test('全空格视为空值放行', () {
        expect(Validators.validatePhone('   '), null);
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

    // ===== 以下为本次新增：补齐全部 13 个 static 校验函数 + 边界值 =====

    group('validateIdCard 补充边界', () {
      test('18 位校验码为小写 x 时应通过（源码会 toUpperCase）', () {
        expect(Validators.validateIdCard('11010519491231002x'), null);
      });

      test('18 位前 17 位含字母应报格式不正确', () {
        // 前 17 位里混入字母（长度仍为 18）
        expect(Validators.validateIdCard('1101051949123100AX'), '身份证号格式不正确');
      });
    });

    group('validateName 边界值', () {
      test('正好 2 / 20 个字符应通过', () {
        expect(Validators.validateName('张三'), null); // 2
        expect(Validators.validateName('一二三四五六七八九十一二三四五六七八二十'), null); // 20
      });
    });

    group('validateAddress 边界值', () {
      test('正好 200 字符应通过', () {
        expect(Validators.validateAddress('A' * 200), null);
      });
    });

    group('validateRemark', () {
      test('空或 <=500 字符返回 null', () {
        expect(Validators.validateRemark(null), null);
        expect(Validators.validateRemark(''), null);
        expect(Validators.validateRemark('普通备注'), null);
        expect(Validators.validateRemark('B' * 500), null);
      });

      test('超过 500 字符报错', () {
        expect(Validators.validateRemark('B' * 501), '备注长度不能超过500个字符');
      });
    });

    group('validateLandArea 边界值', () {
      test('0 与 99999 边界应通过', () {
        expect(Validators.validateLandArea('0'), null);
        expect(Validators.validateLandArea('99999'), null);
      });
    });

    // 三个公益林/商品林面积校验：结构相同，仅错误文案不同，表驱动覆盖
    group('validateLocalWelfareForestArea', () {
      test('空/合法/非法/负数/超界（表驱动）', () {
        expect(Validators.validateLocalWelfareForestArea(null), null);
        expect(Validators.validateLocalWelfareForestArea(''), null);
        expect(Validators.validateLocalWelfareForestArea('12.5'), null);
        expect(Validators.validateLocalWelfareForestArea('0'), null);
        expect(Validators.validateLocalWelfareForestArea('99999'), null);
        expect(Validators.validateLocalWelfareForestArea('abc'), '地方公益林面积必须是数字');
        expect(Validators.validateLocalWelfareForestArea('-1'), '地方公益林面积不能为负数');
        expect(Validators.validateLocalWelfareForestArea('100000'), '地方公益林面积数值过大');
      });
    });

    group('validateNationalWelfareForestArea', () {
      test('空/合法/非法/负数/超界（表驱动）', () {
        expect(Validators.validateNationalWelfareForestArea(null), null);
        expect(Validators.validateNationalWelfareForestArea(''), null);
        expect(Validators.validateNationalWelfareForestArea('8.8'), null);
        expect(Validators.validateNationalWelfareForestArea('abc'), '国家公益林面积必须是数字');
        expect(Validators.validateNationalWelfareForestArea('-1'), '国家公益林面积不能为负数');
        expect(Validators.validateNationalWelfareForestArea('100000'), '国家公益林面积数值过大');
      });
    });

    group('validateCommercialForestArea', () {
      test('空/合法/非法/负数/超界（表驱动）', () {
        expect(Validators.validateCommercialForestArea(null), null);
        expect(Validators.validateCommercialForestArea(''), null);
        expect(Validators.validateCommercialForestArea('6.6'), null);
        expect(Validators.validateCommercialForestArea('abc'), '非国有天然商品林面积必须是数字');
        expect(Validators.validateCommercialForestArea('-1'), '非国有天然商品林面积不能为负数');
        expect(Validators.validateCommercialForestArea('100000'), '非国有天然商品林面积数值过大');
      });
    });

    group('extractBirthday / extractGender 补充', () {
      test('非法长度（如 16 位）应返回 null', () {
        expect(Validators.extractBirthday('1234567890123456'), isNull);
        expect(Validators.extractGender('1234567890123456'), isNull);
      });

      test('生日段含非数字应走 catch 返回 null', () {
        // 长度 18，但生日段（6..14）含字母，int.parse 失败 -> catch -> null
        expect(Validators.extractBirthday('11010519AB1231001X'), isNull);
      });

      test('性别位含非数字应走 catch 返回 null', () {
        // 长度 18，但第 16 位（性别位）非数字
        expect(Validators.extractGender('1101051990010100X5'), isNull);
      });
    });
  });
}
