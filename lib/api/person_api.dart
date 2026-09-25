
import 'package:dio/dio.dart';
import '../models/person.dart';
import 'api_client.dart';

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
    } catch (e) {
      throw Exception('更新失败: $e');
    }
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
