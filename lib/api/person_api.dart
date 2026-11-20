
import 'package:dio/dio.dart';
import '../models/person.dart';
import 'api_client.dart';

/// 网络层失败（超时、连不上服务器）：调用方可将数据转入离线队列。
/// 服务端明确返回 4xx/5xx 时不走这里，避免把校验错误永久排进队列反复重试。
class OfflineQueueException implements Exception {
  final String message;
  OfflineQueueException(this.message);

  @override
  String toString() => message;
}

/// 服务端 409：记录在离线期间被其他人改过。
/// 必须单独成类，同步层才能把"冲突"和"普通失败"分开处理——
/// 冲突不能重试，只能让用户人工选择保留哪一边。
class PersonConflictException implements Exception {
  final String message;
  PersonConflictException(this.message);

  @override
  String toString() => message;
}

class PersonApi {
  static final _dio = ApiClient().dio;
  
  
  static Future<List<Person>> searchByName(String name) async {
    try {
      final response = await _dio.get('/api/search', queryParameters: {
        'name': name,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Person.fromJson(json)).toList();
      } else {
        throw Exception('查询失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('查询失败: $e');
    }
  }
  
  
  static Future<List<Person>> searchAdvanced({
    String? name,
    String? idCard,
    String? huHao,
    String? phone,
    String? address,
    int? ageMin,
    int? ageMax,
    String? disability,
    String? disLevel,
    String? dibao,
    String? tekun,
    String? tekunType,
    String? poorType,
    String? relation,
    String? isDead,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/api/search/advanced', queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (idCard != null && idCard.isNotEmpty) 'id_card': idCard,
        if (huHao != null && huHao.isNotEmpty) 'hu_hao': huHao,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (ageMin != null) 'age_min': ageMin,
        if (ageMax != null) 'age_max': ageMax,
        if (disability != null && disability.isNotEmpty) 'disability': disability,
        if (disLevel != null && disLevel.isNotEmpty) 'dis_level': disLevel,
        if (dibao != null && dibao.isNotEmpty) 'dibao': dibao,
        if (tekun != null && tekun.isNotEmpty) 'tekun': tekun,
        if (tekunType != null && tekunType.isNotEmpty) 'tekun_type': tekunType,
        if (poorType != null && poorType.isNotEmpty) 'poor_type': poorType,
        if (relation != null && relation.isNotEmpty) 'relation': relation,
        if (isDead != null && isDead.isNotEmpty) 'is_dead': isDead,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Person.fromJson(json)).toList();
      } else {
        throw Exception('搜索失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }
  
  
  static Future<Person> getPersonDetail(String idCard) async {
    try {
      final response = await _dio.get('/api/person/$idCard');

      if (response.statusCode == 200) {
        return Person.fromJson(response.data['person']);
      } else {
        throw Exception('获取详情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取详情失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getPerson(String idCard) async {
    try {
      final response = await _dio.get('/api/person/$idCard');

      if (response.statusCode == 200) {
        return response.data['person'];
      } else {
        throw Exception('获取人员信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取人员信息失败: $e');
    }
  }

  
  static Future<bool> addPerson(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/person', data: data);
      final success = response.statusCode == 200 && response.data['success'] == true;
      
      
      if (success && data['id_card'] != null) {
        await ApiClient().invalidatePath('GET', '/api/person/${data['id_card']}');
        
        if (data['hu_hao'] != null) {
          await ApiClient().invalidatePath('GET', '/api/family/${data['hu_hao']}');
        }
      }
      
      return success;
    } on DioException catch (e) {
      throw _mapPersonWriteError(e, '添加失败');
    } catch (e) {
      throw Exception('添加失败: $e');
    }
  }

  
  static Future<bool> deletePerson(String idCard) async {
    try {
      final response = await _dio.delete('/api/person/$idCard');
      final success = response.statusCode == 200 && response.data['success'] == true;
      
      
      if (success) {
        await ApiClient().invalidatePath('GET', '/api/person/$idCard');
      }
      
      return success;
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }
  
  
  static Future<List<Person>> getFamilyMembers(String huHao) async {
    try {
      final response = await _dio.get('/api/family/$huHao');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['members'] ?? [];
        return data.map((json) => Person.fromJson(json)).toList();
      } else {
        throw Exception('获取家庭成员失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取家庭成员失败: $e');
    }
  }

  /// 按人聚合 6 类补贴发放记录（低保 / 高龄 / 地力 / 残疾护理 / 养老 / 特困）
  ///
  /// 服务端 `/api/person/<idCard>/subsidies` 返回：
  /// `{id_card, person_name, total_count, truncated, by_module[], records[]}`
  static Future<Map<String, dynamic>> getPersonSubsidies(String idCard) async {
    try {
      final response = await _dio.get('/api/person/$idCard/subsidies');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        throw Exception('获取补贴发放记录失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取补贴发放记录失败: $e');
    }
  }

  /// 家庭成员原始数据（保留服务端额外字段：subsidy_amount / student_mark）
  ///
  /// 与 [getFamilyMembers] 同一接口，但返回原始 Map，供"按户一档"展示使用。
  static Future<List<Map<String, dynamic>>> getFamilyMembersRaw(
      String huHao) async {
    try {
      final response = await _dio.get('/api/family/$huHao');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['members'] ?? [];
        return data
            .map((json) => Map<String, dynamic>.from(json as Map))
            .toList();
      } else {
        throw Exception('获取家庭成员失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取家庭成员失败: $e');
    }
  }

  /// 待核销清单：已标记死亡/迁出、但名下仍挂着补贴发放记录的人员
  static Future<Map<String, dynamic>> getPendingCorrection() async {
    try {
      final response = await _dio.get('/api/persons/pending-correction');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        throw Exception('获取待核销清单失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取待核销清单失败: $e');
    }
  }

  /// 村级数据体检：按常见数据质量问题分组返回待补录人员
  static Future<Map<String, dynamic>> getDataHealth() async {
    try {
      final response = await _dio.get('/api/persons/data-health');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        throw Exception('获取数据体检结果失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取数据体检结果失败: $e');
    }
  }
  
  
  static Future<bool> updatePerson(String idCard, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/person/$idCard', data: data);
      final success = response.statusCode == 200 && response.data['success'] == true;
      
      
      if (success) {
        
        await ApiClient().invalidatePath('GET', '/api/person/$idCard');
        
        
        if (data['hu_hao'] != null) {
          await ApiClient().invalidatePath('GET', '/api/family/${data['hu_hao']}');
        }
      }
      
      return success;
    } on DioException catch (e) {
      throw _mapPersonWriteError(e, '更新失败');
    } catch (e) {
      throw Exception('更新失败: $e');
    }
  }

  /// 把 DioException 分成两类：
  /// - 网络层失败 → [OfflineQueueException]，页面据此转存离线队列；
  /// - 服务端有响应（400 校验、401、500 等）→ 普通异常，直接提示，不入队。
  static Object _mapPersonWriteError(DioException e, String action) {
    if (e.response?.statusCode == 409) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : '服务器记录已被其他人修改';
      return PersonConflictException(message);
    }

    final typeName = e.type.name;
    final isNetworkFailure = e.response == null &&
        typeName != 'badCertificate' &&
        typeName != 'cancel';
    if (isNetworkFailure) {
      return OfflineQueueException('网络不可用');
    }

    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return Exception(data['error'].toString());
    }
    return Exception(
        '$action：服务器返回 ${e.response?.statusCode ?? typeName}');
  }
  
  
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _dio.get('/api/statistics');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取统计失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取统计失败: $e');
    }
  }

  
  static Future<bool> updateEducation(String personId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/person/$personId/education', data: data);
      final success = response.statusCode == 200 && response.data['success'] == true;

      
      if (success) {
        await ApiClient().invalidatePath('GET', '/api/person/$personId');
      }

      return success;
    } catch (e) {
      throw Exception('更新就读信息失败: $e');
    }
  }
}
