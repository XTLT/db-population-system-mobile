
import 'api_client.dart';

class StatisticsApi {
  static final _dio = ApiClient().dio;
  
  
  static Future<Map<String, dynamic>> getPersonStatistics() async {
    try {
      final response = await _dio.get('/api/statistics');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取统计失败');
      }
    } catch (e) {
      throw Exception('获取统计失败: $e');
    }
  }
  
  
  static Future<Map<String, dynamic>> getStudentStatistics() async {
    try {
      final response = await _dio.get('/api/students/statistics');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取学生统计失败');
      }
    } catch (e) {
      throw Exception('获取学生统计失败: $e');
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> getAgeDistribution() async {
    try {
      final response = await _dio.get('/api/statistics/age_distribution');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['distribution'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> getVillageStatistics() async {
    try {
      final response = await _dio.get('/api/statistics/by_village');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['villages'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  
  static Future<Map<String, dynamic>> getTrendData({
    String? startDate,
    String? endDate,
    String groupBy = 'month',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'group_by': groupBy,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get('/api/statistics/trend', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取趋势数据失败');
      }
    } catch (e) {
      throw Exception('获取趋势数据失败: $e');
    }
  }

  
  static Future<Map<String, int>> getDistribution(String field) async {
    try {
      final response = await _dio.get('/api/statistics/distribution', queryParameters: {'field': field});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data.map((key, value) => MapEntry(key, value as int));
      } else {
        throw Exception('获取分布数据失败');
      }
    } catch (e) {
      throw Exception('获取分布数据失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getComparison({List<String>? dimensions}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dimensions != null && dimensions.isNotEmpty) {
        
        queryParams['dimensions'] = dimensions;
      }

      final response = await _dio.get('/api/statistics/comparison', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取对比数据失败');
      }
    } catch (e) {
      throw Exception('获取对比数据失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getLandSubsidyStatistics({String? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get('/api/land_subsidy/statistics', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取地力补贴统计失败');
      }
    } catch (e) {
      throw Exception('获取地力补贴统计失败: $e');
    }
  }

  /// 获取待遇发放年份列表
  static Future<List<String>> getTreatmentPaymentYears() async {
    try {
      final response = await _dio.get('/api/treatment_payment/years');

      if (response.statusCode == 200) {
        return List<String>.from(response.data['years'] ?? []);
      } else {
        throw Exception('获取待遇发放年份数据失败');
      }
    } catch (e) {
      throw Exception('获取待遇发放年份数据失败: $e');
    }
  }

  /// 获取养老保险年份列表
  static Future<List<String>> getPensionInsuranceYears() async {
    try {
      final response = await _dio.get('/api/pension_insurance/years');

      if (response.statusCode == 200) {
        return List<String>.from(response.data['years'] ?? []);
      } else {
        throw Exception('获取养老保险年份数据失败');
      }
    } catch (e) {
      throw Exception('获取养老保险年份数据失败: $e');
    }
  }

  /// 获取待遇发放可用月份列表
  static Future<List<String>> getTreatmentPaymentPeriods() async {
    try {
      final response = await _dio.get('/api/treatment_payment/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取养老保险可用月份列表
  static Future<List<String>> getPensionInsurancePeriods() async {
    try {
      final response = await _dio.get('/api/pension_insurance/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询待遇发放记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryTreatmentPayments({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final response = await _dio.get('/api/treatment_payment', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['payments'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询养老保险记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryPensionInsurance({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final response = await _dio.get('/api/pension_insurance', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['records'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取低保发放可用月份列表
  static Future<List<String>> getDibaoPaymentPeriods() async {
    try {
      final response = await _dio.get('/api/dibao_payment/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取特困发放可用月份列表
  static Future<List<String>> getTekunPaymentPeriods() async {
    try {
      final response = await _dio.get('/api/tekun_payment/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询低保发放记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryDibaoPayments({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final response = await _dio.get('/api/dibao_payment', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['records'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询特困发放记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryTekunPayments({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;

      final response = await _dio.get('/api/tekun_payment', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['records'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取残疾人护理补贴可用月份列表
  static Future<List<String>> getDisabilityCarePaymentPeriods() async {
    try {
      final response = await _dio.get('/api/disability_care_payment/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询残疾人护理补贴发放记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryDisabilityCarePayments({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      final response = await _dio.get('/api/disability_care_payment', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final records = response.data['records'];
        if (records is List) {
          return records.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取高龄补贴可用月份列表
  static Future<List<String>> getElderlyAllowancePeriods() async {
    try {
      final response = await _dio.get('/api/elderly_allowance/periods');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['periods'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 查询高龄补贴发放记录（按月份+身份证号/姓名）
  static Future<List<Map<String, dynamic>>> queryElderlyAllowances({
    String? period,
    String? idCard,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null && period.isNotEmpty && period != '全部') queryParams['period'] = period;
      if (idCard != null && idCard.isNotEmpty) queryParams['id_card'] = idCard;
      if (name != null && name.isNotEmpty) queryParams['name'] = name;
      final response = await _dio.get('/api/elderly_allowance', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final records = response.data['records'];
        if (records is List) {
          return records.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

