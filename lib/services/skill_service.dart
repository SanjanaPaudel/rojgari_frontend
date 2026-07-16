import 'dart:convert';
import '../core/constants/api_urls.dart';
import '../models/skill_model.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class SkillService {
  final ApiService _apiService = ApiService();

  Future<List<Skill>> getSkills() async {
    //It returns the list of skill obj in comming future
    final response = await _apiService.get(ApiUrls.workerSkills);

    if (response.statusCode == 200) {
      final data = jsonDecode(
        response.body,
      ); //"The backend's response arrives as a raw JSON string. jsonDecode parses that string and turns it into a nested Dart Map, which gets stored in data."

      return (data["skills"]
              as List) //returns the value of skill(which is as list) that was send in response . "skills": [ {...}, {...}, {...} ]
          .map(
            (skill) => Skill.fromJson(skill),
          ) // .map() calls Skill.fromJson on each item in this list. and converts into dart objects. The item is temporarily stored in the variable skill in each iteration. Returns the output into Skill
          .toList(); // Aftter collecting all new Skill obj collects into a list
    }
    throw Exception("Failed to load skills.");
  }

  // Used during signup flow (skill_selection_screen.dart)
  Future<http.Response> selectSkills(List<int> skillIds) async {
    return await _apiService.post(ApiUrls.selectWorkerSkills, {
      "skills": skillIds,
    });
  }

  // Used in profile "Add Skill" flow (technician_skill_selection_screen.dart)
  // PUT /api/auth/worker/update-skills/
  // Request body: {"skills": [id1, id2, ...]}
  // Success response: {"message": "Skills updated successfully.", "skills": ["Name1", ...]}
  Future<http.Response> updateSkills(List<int> skillIds) async {
    return await _apiService.put(ApiUrls.updateWorkerSkills, {
      "skill_ids": skillIds,
    });
  }
}
