import 'dart:convert';

import '../core/constants/api_urls.dart';
import '../models/skill_model.dart';
import 'api_service.dart';

class SkillService {
  final ApiService _apiService = ApiService();

  /// GET /worker/skills/
  Future<List<Skill>> getSkills() async {
    final response = await _apiService.get(ApiUrls.workerSkills);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data["skills"] as List)
          .map((skill) => Skill.fromJson(skill))
          .toList();
    }

    throw Exception("Failed to load skills.");
  }

  /// POST /worker/select-skills/
  Future<String?> selectSkills(List<int> skillIds) async {
    final response = await _apiService.post(
      ApiUrls.selectWorkerSkills,
      {
        "skills": skillIds,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return null; // Success
    }

    if (data["skills"] != null) {
      return data["skills"][0];
    }

    return "Something went wrong.";
  }
}