
class Validators {
  
  // 口径与服务端 utils/common/validate_id_card.py 完全一致（提示文案亦同）：
  // 去所有空白 -> 必须 18 位（前 17 位数字 + 末位数字或 X）-> 校验位 -> 出生日期。
  static String? validateIdCard(String? value) {
    final idCard = (value ?? '').replaceAll(RegExp(r'\s'), '').toUpperCase();

    if (idCard.isEmpty) {
      return '身份证号不能为空';
    }
    if (idCard.length != 18) {
      return '身份证号必须为18位';
    }
    if (!RegExp(r'^\d{17}$').hasMatch(idCard.substring(0, 17))) {
      return '身份证号前17位必须为数字';
    }
    if (!RegExp(r'^[\dX]$').hasMatch(idCard[17])) {
      return '身份证号最后一位必须为数字或X';
    }

    final weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    final checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];

    int sum = 0;
    for (int i = 0; i < 17; i++) {
      sum += int.parse(idCard[i]) * weights[i];
    }

    if (idCard[17] != checkCodes[sum % 11]) {
      return '身份证号校验位错误';
    }

    // 出生日期：年份 1900~今年、月份 1-12、日按大小月与闰年判断
    final year = int.parse(idCard.substring(6, 10));
    final month = int.parse(idCard.substring(10, 12));
    final day = int.parse(idCard.substring(12, 14));

    if (year < 1900 || year > DateTime.now().year) {
      return '身份证号出生年份无效';
    }
    if (month < 1 || month > 12) {
      return '身份证号出生月份无效';
    }
    if (day < 1 || day > 31) {
      return '身份证号出生日期无效';
    }
    if ([4, 6, 9, 11].contains(month) && day > 30) {
      return '身份证号出生日期无效';
    }
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      if (day > (isLeap ? 29 : 28)) {
        return '身份证号出生日期无效';
      }
    }

    return null;
  }
  
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '姓名不能为空';
    }
    
    if (value.length < 2 || value.length > 20) {
      return '姓名长度应为2-20个字符';
    }
    
    
    if (!RegExp(r'^[\u4e00-\u9fa5a-zA-Z]+$').hasMatch(value)) {
      return '姓名只能包含中文和字母';
    }
    
    return null;
  }
  
  
  // 口径与服务端 utils/common/validate_phone.py 完全一致（提示文案亦同）：
  // 去首尾空白并剔除 "-" 与空白 -> 空值放行 -> 仅 11 位手机号，座机拒绝。
  static String? validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[-\s]'), '');
    if (phone.isEmpty) {
      return null;
    }

    if (RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      return null;
    }

    return '电话号码格式无效，请输入11位手机号';
  }
  
  
  static String? validateAddress(String? value) {
    if (value != null && value.length > 200) {
      return '地址长度不能超过200个字符';
    }
    return null;
  }
  
  
  static String? validateRemark(String? value) {
    if (value != null && value.length > 500) {
      return '备注长度不能超过500个字符';
    }
    return null;
  }
  
  
  static String? validateLandArea(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '土地面积必须是数字';
    }
    
    if (number < 0) {
      return '土地面积不能为负数';
    }
    
    if (number > 99999) {
      return '土地面积数值过大';
    }

    return null;
  }


  static String? validateLocalWelfareForestArea(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '地方公益林面积必须是数字';
    }

    if (number < 0) {
      return '地方公益林面积不能为负数';
    }

    if (number > 99999) {
      return '地方公益林面积数值过大';
    }

    return null;
  }


  static String? validateNationalWelfareForestArea(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '国家公益林面积必须是数字';
    }

    if (number < 0) {
      return '国家公益林面积不能为负数';
    }

    if (number > 99999) {
      return '国家公益林面积数值过大';
    }

    return null;
  }


  static String? validateCommercialForestArea(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '非国有天然商品林面积必须是数字';
    }

    if (number < 0) {
      return '非国有天然商品林面积不能为负数';
    }

    if (number > 99999) {
      return '非国有天然商品林面积数值过大';
    }

    return null;
  }


  static String? validateSocialCard(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
      return '社保卡号只能包含字母和数字';
    }
    
    if (value.length > 30) {
      return '社保卡号长度不能超过30个字符';
    }
    
    return null;
  }
  
  
  static DateTime? extractBirthday(String idCard) {
    try {
      String birthdayStr;
      
      if (idCard.length == 18) {
        birthdayStr = idCard.substring(6, 14);
      } else if (idCard.length == 15) {
        birthdayStr = '19${idCard.substring(6, 12)}';
      } else {
        return null;
      }
      
      final year = int.parse(birthdayStr.substring(0, 4));
      final month = int.parse(birthdayStr.substring(4, 6));
      final day = int.parse(birthdayStr.substring(6, 8));
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
  
  
  static String? extractGender(String idCard) {
    try {
      int genderCode;
      
      if (idCard.length == 18) {
        genderCode = int.parse(idCard[16]);
      } else if (idCard.length == 15) {
        genderCode = int.parse(idCard[14]);
      } else {
        return null;
      }
      
      return genderCode % 2 == 1 ? '男' : '女';
    } catch (e) {
      return null;
    }
  }
  
  
  static int calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    
    if (now.month < birthday.month || 
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    
    return age;
  }
}
