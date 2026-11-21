
class Education {
  final String? schoolName;
  final String? grade;
  final String? className;
  final String? guardian;
  final String? guardianPhone;
  final String? isLeftBehind;
  final String? studentStatus;
  final String? enrollmentDate;
  final String? graduationDate;

  Education({
    this.schoolName,
    this.grade,
    this.className,
    this.guardian,
    this.guardianPhone,
    this.isLeftBehind,
    this.studentStatus,
    this.enrollmentDate,
    this.graduationDate,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      schoolName: json['school_name'],
      grade: json['grade'],
      className: json['class_name'],
      guardian: json['guardian'],
      guardianPhone: json['guardian_phone'],
      isLeftBehind: json['is_left_behind'],
      studentStatus: json['student_status'],
      enrollmentDate: json['enrollment_date'],
      graduationDate: json['graduation_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'school_name': schoolName,
      'grade': grade,
      'class_name': className,
      'guardian': guardian,
      'guardian_phone': guardianPhone,
      'is_left_behind': isLeftBehind,
      'student_status': studentStatus,
      'enrollment_date': enrollmentDate,
      'graduation_date': graduationDate,
    };
  }
}


class Person {
  final String? id;
  final String? idCard;
  final String? name;
  final String? huHao;
  final String? address;
  final String? groupName;
  final String? relation;
  final String? phone;
  final String? age;
  final String? isDead;
  final String? deathDate;
  final String? remark;
  final String? poorType;
  final String? disability;
  final String? disabilityType;
  final String? disLevel;
  final String? dibao;
  final String? jisheng;
  final String? tekun;
  final String? tekunType;
  final String? socialCard1;
  final String? socialCard2;
  final String? socialCard3;
  final String? socialCard2Source;
  final String? socialCard3Source;
  final String? isMigrated;
  final String? landArea;
  final String? landAreaChangeReason;
  final String? landAreaChangeTime;
  final String? migrationDate;
  final String? migrationPlace;
  final String? migrationReason;
  final String? localWelfareForestArea;
  final String? localWelfareForestChangeReason;
  final String? localWelfareForestChangeTime;
  final String? nationalWelfareForestArea;
  final String? nationalWelfareForestChangeReason;
  final String? nationalWelfareForestChangeTime;
  final String? commercialForestArea;
  final String? commercialForestChangeReason;
  final String? commercialForestChangeTime;
  final Education? education;

  /// 服务端记录的最后修改时间。离线编辑时作为冲突检测基线，
  /// 同步时随 payload 回传，服务端据此判断期间是否被别人改过。
  final String? updatedAt;

  Person({
    this.id,
    this.idCard,
    this.name,
    this.huHao,
    this.address,
    this.groupName,
    this.relation,
    this.phone,
    this.age,
    this.isDead,
    this.deathDate,
    this.remark,
    this.poorType,
    this.disability,
    this.disabilityType,
    this.disLevel,
    this.dibao,
    this.jisheng,
    this.tekun,
    this.tekunType,
    this.socialCard1,
    this.socialCard2,
    this.socialCard3,
    this.socialCard2Source,
    this.socialCard3Source,
    this.isMigrated,
    this.landArea,
    this.landAreaChangeReason,
    this.landAreaChangeTime,
    this.migrationDate,
    this.migrationPlace,
    this.migrationReason,
    this.localWelfareForestArea,
    this.localWelfareForestChangeReason,
    this.localWelfareForestChangeTime,
    this.nationalWelfareForestArea,
    this.nationalWelfareForestChangeReason,
    this.nationalWelfareForestChangeTime,
    this.commercialForestArea,
    this.commercialForestChangeReason,
    this.commercialForestChangeTime,
    this.education,
    this.updatedAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      idCard: json['id_card'],
      name: json['name'],
      huHao: json['hu_hao'],
      address: json['address'],
      groupName: json['group_name'],
      relation: json['relation'],
      phone: json['phone'],
      age: json['age'],
      isDead: json['is_dead'],
      deathDate: json['death_date'],
      remark: json['remark'],
      poorType: json['poor_type'],
      disability: json['disability'],
      disabilityType: json['disability_type'],
      disLevel: json['dis_level'],
      dibao: json['dibao'],
      jisheng: json['jisheng'],
      tekun: json['tekun'],
      tekunType: json['tekun_type'],
      socialCard1: json['social_card1'],
      socialCard2: json['social_card2'],
      socialCard3: json['social_card3'],
      socialCard2Source: json['social_card2_source'],
      socialCard3Source: json['social_card3_source'],
      isMigrated: json['is_migrated'],
      landArea: json['land_area'],
      landAreaChangeReason: json['land_area_change_reason'],
      landAreaChangeTime: json['land_area_change_time'],
      migrationDate: json['migration_date'],
      migrationPlace: json['migration_place'],
      migrationReason: json['migration_reason'],
      localWelfareForestArea: json['local_welfare_forest_area'],
      localWelfareForestChangeReason: json['local_welfare_forest_change_reason'],
      localWelfareForestChangeTime: json['local_welfare_forest_change_time'],
      nationalWelfareForestArea: json['national_welfare_forest_area'],
      nationalWelfareForestChangeReason: json['national_welfare_forest_change_reason'],
      nationalWelfareForestChangeTime: json['national_welfare_forest_change_time'],
      commercialForestArea: json['commercial_forest_area'],
      commercialForestChangeReason: json['commercial_forest_change_reason'],
      commercialForestChangeTime: json['commercial_forest_change_time'],
      updatedAt: json['updated_at']?.toString(),
      education: json['education'] != null
          ? Education.fromJson(json['education'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_card': idCard,
      'name': name,
      'hu_hao': huHao,
      'address': address,
      'group_name': groupName,
      'relation': relation,
      'phone': phone,
      'age': age,
      'is_dead': isDead,
      'death_date': deathDate,
      'remark': remark,
      'poor_type': poorType,
      'disability': disability,
      'disability_type': disabilityType,
      'dis_level': disLevel,
      'dibao': dibao,
      'jisheng': jisheng,
      'tekun': tekun,
      'tekun_type': tekunType,
      'social_card1': socialCard1,
      'social_card2': socialCard2,
      'social_card3': socialCard3,
      'social_card2_source': socialCard2Source,
      'social_card3_source': socialCard3Source,
      'is_migrated': isMigrated,
      'land_area': landArea,
      'land_area_change_reason': landAreaChangeReason,
      'land_area_change_time': landAreaChangeTime,
      'migration_date': migrationDate,
      'migration_place': migrationPlace,
      'migration_reason': migrationReason,
      'local_welfare_forest_area': localWelfareForestArea,
      'local_welfare_forest_change_reason': localWelfareForestChangeReason,
      'local_welfare_forest_change_time': localWelfareForestChangeTime,
      'national_welfare_forest_area': nationalWelfareForestArea,
      'national_welfare_forest_change_reason': nationalWelfareForestChangeReason,
      'national_welfare_forest_change_time': nationalWelfareForestChangeTime,
      'commercial_forest_area': commercialForestArea,
      'commercial_forest_change_reason': commercialForestChangeReason,
      'commercial_forest_change_time': commercialForestChangeTime,
      'updated_at': updatedAt,
      'education': education?.toJson(),
    };
  }

  
  String get displayName => name ?? '未知';

  
  String get displayAge => age != null && age!.isNotEmpty ? '$age岁' : '未知';

  
  bool get isDeceased => isDead == '是';
}
