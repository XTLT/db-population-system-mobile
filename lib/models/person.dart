
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
  final String? relation;
  final String? phone;
  final String? age;
  final String? isDead;
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
  final String? isMigrated;
  final String? landArea;
  final Education? education;

  Person({
    this.id,
    this.idCard,
    this.name,
    this.huHao,
    this.address,
    this.relation,
    this.phone,
    this.age,
    this.isDead,
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
    this.isMigrated,
    this.landArea,
    this.education,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      idCard: json['id_card'],
      name: json['name'],
      huHao: json['hu_hao'],
      address: json['address'],
      relation: json['relation'],
      phone: json['phone'],
      age: json['age'],
      isDead: json['is_dead'],
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
      isMigrated: json['is_migrated'],
      landArea: json['land_area'],
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
      'relation': relation,
      'phone': phone,
      'age': age,
      'is_dead': isDead,
      'remark': remark,
      'poor_type': poorType,
      'disability': disability,
      'dis_level': disLevel,
      'dibao': dibao,
      'jisheng': jisheng,
      'tekun': tekun,
      'tekun_type': tekunType,
      'social_card1': socialCard1,
      'social_card2': socialCard2,
      'social_card3': socialCard3,
      'is_migrated': isMigrated,
      'land_area': landArea,
    };
  }

  
  String get displayName => name ?? '未知';

  
  String get displayAge => age != null && age!.isNotEmpty ? '$age岁' : '未知';

  
  bool get isDeceased => isDead == '是';
}
