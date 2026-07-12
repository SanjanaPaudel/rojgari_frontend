import 'dart:convert';
import '../core/constants/api_urls.dart';
import '../models/skill_model.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;


class SkillService {
  final ApiService _apiService = ApiService();


  Future<List<Skill>> getSkills() async {  //It returns the list of skill obj in comming future
    final response = await _apiService.get(ApiUrls.workerSkills);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); //"The backend's response arrives as a raw JSON string. jsonDecode parses that string and turns it into a nested Dart Map, which gets stored in data."

      return (data["skills"] as List) //returns the value of skill(which is as list) that was send in response . "skills": [ {...}, {...}, {...} ]
          .map((skill) => Skill.fromJson(skill)) //
          .toList();
    }
    throw Exception("Failed to load skills.");
  }

  /// POST /worker/select-skills/
  Future<http.Response> selectSkills(List<int> skillIds) async {
    return await _apiService.post(
      ApiUrls.selectWorkerSkills,
      {
        "skills": skillIds,
      },
    );
  }
}