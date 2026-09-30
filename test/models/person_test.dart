import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/person.dart';

void main() {
  group('Person Model Tests', () {
    test('should create Person from JSON', () {
      final json = {
        'id_card': '110101199001011234',
        'name': '张三',
        'hu_hao': '123456',
        'address': '北京市朝阳区',
        'relation': '户主',
        'phone': '13800138000',
        'age': '30',
        'is_dead': '否',
        'remark': '测试备注',
        'poor_type': '脱贫户',
        'disability': '否',
        'dis_level': null,
        'dibao': '否',
        'jisheng': '是',
        'social_card1': '123456789',
        'social_card2': null,
        'social_card3': null,
        'land_area': '10.5',
        'local_welfare_forest_area': '3.0',
        'local_welfare_forest_change_reason': '初始登记',
        'local_welfare_forest_change_time': '2024-01-15',
        'national_welfare_forest_area': '4.0',
        'national_welfare_forest_change_reason': '初始登记',
        'national_welfare_forest_change_time': '2024-01-15',
        'commercial_forest_area': '1.5',
        'commercial_forest_change_reason': '初始登记',
        'commercial_forest_change_time': '2024-01-15',
      };

      final person = Person.fromJson(json);

      expect(person.idCard, '110101199001011234');
      expect(person.name, '张三');
      expect(person.huHao, '123456');
      expect(person.address, '北京市朝阳区');
      expect(person.relation, '户主');
      expect(person.phone, '13800138000');
      expect(person.age, '30');
      expect(person.isDead, '否');
      expect(person.remark, '测试备注');
      expect(person.poorType, '脱贫户');
      expect(person.disability, '否');
      expect(person.disLevel, isNull);
      expect(person.dibao, '否');
      expect(person.jisheng, '是');
      expect(person.socialCard1, '123456789');
      expect(person.socialCard2, isNull);
      expect(person.socialCard3, isNull);
      expect(person.landArea, '10.5');
      expect(person.localWelfareForestArea, '3.0');
      expect(person.localWelfareForestChangeReason, '初始登记');
      expect(person.localWelfareForestChangeTime, '2024-01-15');
      expect(person.nationalWelfareForestArea, '4.0');
      expect(person.nationalWelfareForestChangeReason, '初始登记');
      expect(person.nationalWelfareForestChangeTime, '2024-01-15');
      expect(person.commercialForestArea, '1.5');
      expect(person.commercialForestChangeReason, '初始登记');
      expect(person.commercialForestChangeTime, '2024-01-15');
    });

    test('should convert Person to JSON', () {
      final person = Person(
        idCard: '110101199001011234',
        name: '张三',
        huHao: '123456',
        address: '北京市朝阳区',
        age: '30',
      );

      final json = person.toJson();

      expect(json['id_card'], '110101199001011234');
      expect(json['name'], '张三');
      expect(json['hu_hao'], '123456');
      expect(json['address'], '北京市朝阳区');
      expect(json['age'], '30');
    });

    test('should handle null values in JSON', () {
      final json = <String, dynamic>{};

      final person = Person.fromJson(json);

      expect(person.idCard, isNull);
      expect(person.name, isNull);
      expect(person.age, isNull);
    });

    test('should return correct display name', () {
      final personWithName = Person(name: '张三');
      expect(personWithName.displayName, '张三');

      final personWithoutName = Person();
      expect(personWithoutName.displayName, '未知');
    });

    test('should return correct display age', () {
      final personWithAge = Person(age: '30');
      expect(personWithAge.displayAge, '30岁');

      final personWithoutAge = Person();
      expect(personWithoutAge.displayAge, '未知');
    });

    test('should correctly determine if deceased', () {
      final deceased = Person(isDead: '是');
      expect(deceased.isDeceased, true);

      final alive = Person(isDead: '否');
      expect(alive.isDeceased, false);

      final unknown = Person();
      expect(unknown.isDeceased, false);
    });

    test('should handle all fields correctly', () {
      final person = Person(
        idCard: '110101199001011234',
        name: '李四',
        huHao: '789012',
        address: '上海市浦东新区',
        relation: '配偶',
        phone: '13900139000',
        age: '28',
        isDead: '否',
        remark: '无',
        poorType: '监测户',
        disability: '是',
        disLevel: '三级',
        dibao: '是',
        jisheng: '否',
        socialCard1: '987654321',
        socialCard2: '111222333',
        socialCard3: '444555666',
        landArea: '15.5',
        localWelfareForestArea: '5.0',
        localWelfareForestChangeReason: '流转',
        localWelfareForestChangeTime: '2024-03-01',
        nationalWelfareForestArea: '6.0',
        nationalWelfareForestChangeReason: '流转',
        nationalWelfareForestChangeTime: '2024-03-01',
        commercialForestArea: '2.5',
        commercialForestChangeReason: '流转',
        commercialForestChangeTime: '2024-03-01',
      );

      expect(person.idCard, '110101199001011234');
      expect(person.name, '李四');
      expect(person.disability, '是');
      expect(person.disLevel, '三级');
      expect(person.socialCard2, '111222333');
      expect(person.landArea, '15.5');
      expect(person.localWelfareForestArea, '5.0');
      expect(person.localWelfareForestChangeReason, '流转');
      expect(person.localWelfareForestChangeTime, '2024-03-01');
      expect(person.nationalWelfareForestArea, '6.0');
      expect(person.nationalWelfareForestChangeReason, '流转');
      expect(person.nationalWelfareForestChangeTime, '2024-03-01');
      expect(person.commercialForestArea, '2.5');
      expect(person.commercialForestChangeReason, '流转');
      expect(person.commercialForestChangeTime, '2024-03-01');
    });

    // ===== 以下为本次新增：全字段 fromJson 断言 =====

    test('fromJson 应解析全部 35 个字段（含 id / disability_type / tekun / 社保卡来源 / is_migrated）', () {
      final json = {
        'id': 'db-001',
        'id_card': '110101199001011234',
        'name': '王五',
        'hu_hao': 'H2024001',
        'address': '广东省广州市天河区',
        'relation': '子女',
        'phone': '13700137000',
        'age': '35',
        'is_dead': '否',
        'remark': '全字段断言',
        'poor_type': '一般农户',
        'disability': '是',
        'disability_type': '视力残疾',
        'dis_level': '二级',
        'dibao': '是',
        'jisheng': '否',
        'tekun': '是',
        'tekun_type': '特困供养',
        'social_card1': 'SC001',
        'social_card2': 'SC002',
        'social_card3': 'SC003',
        'social_card2_source': '手工录入',
        'social_card3_source': '读卡',
        'is_migrated': '否',
        'land_area': '12.3',
        'local_welfare_forest_area': '1.1',
        'local_welfare_forest_change_reason': '调整',
        'local_welfare_forest_change_time': '2024-05-01',
        'national_welfare_forest_area': '2.2',
        'national_welfare_forest_change_reason': '调整',
        'national_welfare_forest_change_time': '2024-05-01',
        'commercial_forest_area': '3.3',
        'commercial_forest_change_reason': '调整',
        'commercial_forest_change_time': '2024-05-01',
      };

      final p = Person.fromJson(json);

      expect(p.id, 'db-001');
      expect(p.idCard, '110101199001011234');
      expect(p.name, '王五');
      expect(p.huHao, 'H2024001');
      expect(p.address, '广东省广州市天河区');
      expect(p.relation, '子女');
      expect(p.phone, '13700137000');
      expect(p.age, '35');
      expect(p.isDead, '否');
      expect(p.remark, '全字段断言');
      expect(p.poorType, '一般农户');
      expect(p.disability, '是');
      // fromJson 读 json['disability_type']，toJson 亦已输出（BUG-03 已修复）
      expect(p.disabilityType, '视力残疾');
      expect(p.disLevel, '二级');
      expect(p.dibao, '是');
      expect(p.jisheng, '否');
      expect(p.tekun, '是');
      expect(p.tekunType, '特困供养');
      expect(p.socialCard1, 'SC001');
      expect(p.socialCard2, 'SC002');
      expect(p.socialCard3, 'SC003');
      expect(p.socialCard2Source, '手工录入');
      expect(p.socialCard3Source, '读卡');
      expect(p.isMigrated, '否');
      expect(p.landArea, '12.3');
      expect(p.localWelfareForestArea, '1.1');
      expect(p.localWelfareForestChangeReason, '调整');
      expect(p.localWelfareForestChangeTime, '2024-05-01');
      expect(p.nationalWelfareForestArea, '2.2');
      expect(p.nationalWelfareForestChangeReason, '调整');
      expect(p.nationalWelfareForestChangeTime, '2024-05-01');
      expect(p.commercialForestArea, '3.3');
      expect(p.commercialForestChangeReason, '调整');
      expect(p.commercialForestChangeTime, '2024-05-01');
      // education 缺省时为 null
      expect(p.education, isNull);
    });

    test('fromJson 应正确解析嵌套 Education', () {
      final json = {
        'id_card': '110101201001011234',
        'name': '赵小六',
        'education': {
          'school_name': '天河区实验小学',
          'grade': 'G4',
          'class_name': '3班',
          'guardian': '赵父',
          'guardian_phone': '13600136000',
          'is_left_behind': '是',
          'student_status': '在读',
          'enrollment_date': '2021-09-01',
          'graduation_date': null,
        },
      };

      final p = Person.fromJson(json);

      expect(p.education, isNotNull);
      expect(p.education?.schoolName, '天河区实验小学');
      expect(p.education?.grade, 'G4');
      expect(p.education?.className, '3班');
      expect(p.education?.guardian, '赵父');
      expect(p.education?.guardianPhone, '13600136000');
      expect(p.education?.isLeftBehind, '是');
      expect(p.education?.studentStatus, '在读');
      expect(p.education?.enrollmentDate, '2021-09-01');
      expect(p.education?.graduationDate, isNull);
    });

    test('toJson 应输出全部 key（含 BUG-03 修复补回的 disability_type 与嵌套 education）', () {
      // BUG-03 已修复：Person.toJson（lib/models/person.dart 第 172 行起）补回了
      //   - 'disability_type'（与 fromJson 第 144 行 json['disability_type'] 对称）
      //   - 嵌套 'education'（与 fromJson 第 166-168 行对称）
      // 离线同步/导出不再丢失残疾类型与学籍信息。
      final person = Person(
        id: 'db-002',
        idCard: '110101199002021234',
        name: '钱七',
        huHao: 'H2024002',
        address: '深圳市南山区',
        relation: '户主',
        phone: '13500135000',
        age: '40',
        isDead: '否',
        remark: 'toJson 断言',
        poorType: '脱贫户',
        disability: '是',
        disabilityType: '听力残疾', // BUG-03 修复后 toJson 会输出
        disLevel: '四级',
        dibao: '否',
        jisheng: '是',
        tekun: '否',
        tekunType: null,
        socialCard1: 'SC1',
        socialCard2: 'SC2',
        socialCard3: 'SC3',
        socialCard2Source: '来源2',
        socialCard3Source: '来源3',
        isMigrated: '否',
        landArea: '8.8',
        localWelfareForestArea: '1.0',
        localWelfareForestChangeReason: '无',
        localWelfareForestChangeTime: '2024-01-01',
        nationalWelfareForestArea: '2.0',
        nationalWelfareForestChangeReason: '无',
        nationalWelfareForestChangeTime: '2024-01-01',
        commercialForestArea: '3.0',
        commercialForestChangeReason: '无',
        commercialForestChangeTime: '2024-01-01',
        education: Education(schoolName: '某校', grade: 'G1'), // BUG-03 修复后 toJson 会输出
      );

      final json = person.toJson();

      // 当前实现确实输出的 key 全部断言
      expect(json['id'], 'db-002');
      expect(json['id_card'], '110101199002021234');
      expect(json['name'], '钱七');
      expect(json['hu_hao'], 'H2024002');
      expect(json['address'], '深圳市南山区');
      expect(json['relation'], '户主');
      expect(json['phone'], '13500135000');
      expect(json['age'], '40');
      expect(json['is_dead'], '否');
      expect(json['remark'], 'toJson 断言');
      expect(json['poor_type'], '脱贫户');
      expect(json['disability'], '是');
      expect(json['dis_level'], '四级');
      expect(json['dibao'], '否');
      expect(json['jisheng'], '是');
      expect(json['tekun'], '否');
      expect(json['tekun_type'], isNull);
      expect(json['social_card1'], 'SC1');
      expect(json['social_card2'], 'SC2');
      expect(json['social_card3'], 'SC3');
      expect(json['social_card2_source'], '来源2');
      expect(json['social_card3_source'], '来源3');
      expect(json['is_migrated'], '否');
      expect(json['land_area'], '8.8');
      expect(json['local_welfare_forest_area'], '1.0');
      expect(json['local_welfare_forest_change_reason'], '无');
      expect(json['local_welfare_forest_change_time'], '2024-01-01');
      expect(json['national_welfare_forest_area'], '2.0');
      expect(json['national_welfare_forest_change_reason'], '无');
      expect(json['national_welfare_forest_change_time'], '2024-01-01');
      expect(json['commercial_forest_area'], '3.0');
      expect(json['commercial_forest_change_reason'], '无');
      expect(json['commercial_forest_change_time'], '2024-01-01');

      // BUG-03 已修复：两个 key 必须存在且值正确
      expect(json['disability_type'], '听力残疾');
      expect(json['education'], isNotNull);
      expect(json['education']['school_name'], '某校');
      expect(json['education']['grade'], 'G1');
    });

    test('Education 自身 fromJson/toJson 对称', () {
      final json = {
        'school_name': '学校A',
        'grade': 'G6',
        'class_name': '5班',
        'guardian': '监护A',
        'guardian_phone': '13100131000',
        'is_left_behind': '否',
        'student_status': '在读',
        'enrollment_date': '2020-09-01',
        'graduation_date': '2026-06-30',
      };
      final e = Education.fromJson(json);
      expect(e.schoolName, '学校A');
      expect(e.grade, 'G6');
      expect(e.className, '5班');
      expect(e.guardian, '监护A');
      expect(e.guardianPhone, '13100131000');
      expect(e.isLeftBehind, '否');
      expect(e.studentStatus, '在读');
      expect(e.enrollmentDate, '2020-09-01');
      expect(e.graduationDate, '2026-06-30');

      final back = e.toJson();
      expect(back['school_name'], '学校A');
      expect(back['grade'], 'G6');
      expect(back['class_name'], '5班');
      expect(back['guardian'], '监护A');
      expect(back['guardian_phone'], '13100131000');
      expect(back['is_left_behind'], '否');
      expect(back['student_status'], '在读');
      expect(back['enrollment_date'], '2020-09-01');
      expect(back['graduation_date'], '2026-06-30');
    });
  });
}
