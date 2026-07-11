import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import 'package:rojgari_frontend_one/widgets/skill_card.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/screens/worker/worker_dashboard_screen.dart';


class SkillSelectionScreen extends StatefulWidget {
  const SkillSelectionScreen({super.key});

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  final SkillService _skillService = SkillService();
  final TextEditingController _searchController = TextEditingController();
  List<Skill> _allSkills = [];
  List<Skill> _filteredSkills = [];
  final Set<int> _selectedSkillIds = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError; // shown if the skill list fails to load
  String? _submitError; // shown above the continue button if the backend any error like: "This field is required."

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await _skillService.getSkills(); // Now skills has the list of the different skill(id,name etc...)
      print("Status Code: $skills");
      print("Raw Response:");
      print(skills);

      setState(() {
        _allSkills = skills;
        _filteredSkills = skills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = "Failed to load skills.";
      });
    }
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredSkills = _allSkills;
      } else {
        _filteredSkills = _allSkills.where((skill) {
          return skill.name
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _submitSkills() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final response =
    await _skillService.selectSkills(_selectedSkillIds.toList());

    final data = jsonDecode(response.body);

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkerDashboardScreen(),
        ),
      );

      return;
    }

    if (response.statusCode == 400) {
      setState(() {
        _submitError = data["skills"]?[0];
      });

      return;
    }

    setState(() {
      _submitError = "Something went wrong.";
    });
  } //skill id send to backend

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Back Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 215,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Your Skills",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2340),
                      ),
                    ),

                    const SizedBox(height: 0),

                    Text(
                      "Choose all the services you are skilled in."
                          " You can select multiple options.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(width: 0),
              Flexible( // Takes only the space available in the row
                child: Image.asset(
                  "assets/images/temple(skill).png",
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSkills,
        decoration: InputDecoration(
          hintText: "Search skills...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: Color(0xFF6A5AE0),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSelectedSkills() {
    final selectedSkills = _allSkills
        .where((skill) => _selectedSkillIds.contains(skill.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Selected Skills (${selectedSkills.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A5AE0),
                ),
              ),

              const Text(
                "You can select more",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: selectedSkills.map((skill) {
              return Chip(
                label: Text(skill.name),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () {
                  setState(() {
                    _selectedSkillIds.remove(skill.id);
                  });
                },
                backgroundColor: const Color(0xFFF3F1FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildSkillGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Text(_loadError!),
      );
    }

    // NEW — add this block here
    if (_filteredSkills.isEmpty) {
      return const Center(
        child: Text(
          "No skills available right now.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        itemCount: _filteredSkills.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final skill = _filteredSkills[index];

          return SkillCard(
            skill: skill,
            isSelected: _selectedSkillIds.contains(skill.id),
            onTap: () {
              setState(() {
                if (_selectedSkillIds.contains(skill.id)) {
                  _selectedSkillIds.remove(skill.id);
                } else {
                  _selectedSkillIds.add(skill.id);
                }
              });
            },
          );
        },
      ),
    );
  } //Create skill container
  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: CustomButton(
        text: "Continue",
        isLoading: _isSubmitting,
        icon: Icons.arrow_forward,
        onPressed: _submitSkills,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildSelectedSkills(),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "All Skills",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: _buildSkillGrid(),
            ),

            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _submitError!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }
}