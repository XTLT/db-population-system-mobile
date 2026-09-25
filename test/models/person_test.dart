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
  });
}
