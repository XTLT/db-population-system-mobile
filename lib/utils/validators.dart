
class Validators {
  
  static String? validateIdCard(String? value) {
    if (value == null || value.isEmpty) {
      return '身份证号不能为空';
    }
    
    
    if (value.length != 15 && value.length != 18) {
      return '身份证号长度不正确';
    }
    
    
    if (value.length == 18) {
      final weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
      final checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
      
      int sum = 0;
      for (int i = 0; i < 17; i++) {
        if (!RegExp(r'\d').hasMatch(value[i])) {
          return '身份证号格式不正确';
        }
        sum += int.parse(value[i]) * weights[i];
      }
      
      final checkCode = checkCodes[sum % 11];
      if (value[17].toUpperCase() != checkCode) {
        return '身份证号校验不通过';
      }
    }
    
    
    if (value.length == 15) {
      if (!RegExp(r'^\d{15}$').hasMatch(value)) {
        return '身份证号格式不正确';
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
  
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    
    
    if (value.length == 11) {
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
        return '手机号格式不正确';
      }
    }
    
    else {
      if (!RegExp(r'^\d{3,4}-?\d{7,8}$').hasMatch(value)) {
        return '电话格式不正确';
      }
    }
    
    return null;
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
