import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import '../../services/storage_service.dart';
import 'package:rojgari_frontend_one/widgets/skill_card.dart';
import 'package:rojgari_frontend_one/widgets/custom_button.dart';
import 'package:rojgari_frontend_one/screens/technician/technician_home_screen.dart';
import 'package:rojgari_frontend_one/screens/auth/login_screen.dart';


class SkillSelectionScreen extends StatefulWidget {
  const SkillSelectionScreen({super.key}); //Constructor

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();   // Flutter needs to know which State belongs to which Widget, the line tell flutter that This State belongs only to _SkillSelectionScreenState() class.
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {

  //These variables hold the state of this screen.
  //Whenever one of these values changes and you call setState(), Flutter rebuilds the UI.

  final SkillService _skillService = SkillService(); //Object of SkillService class
  final TextEditingController _searchController = TextEditingController();
  List<Skill> _allSkills = []; //It only accept Skill obj as a list . Stores all skills from API
  List<Skill> _filteredSkills = []; //Used for filtering skills based on search query
  final Set<int> _selectedSkillIds = {}; //Set instead of List because Sets never allow duplicates. Stores the id of selected skills
  bool _isLoading = true; //Indicator for loading skills
  bool _isSubmitting = false; //Indicator for Sending selected skills to backend
  String? _loadError; // Error while fetching skills.
  String? _submitError; // Error while submitting selected skills.

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {      //this controller allocates resources. When the screen is removed, disposing it prevents resource leaks.
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await _skillService.getSkills(); // SkillService returs List of item Skill(id,name etc...). skills variable now contain List<Skill>

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
  void _filterSkills(String query) { //query is simply whatever the user types
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
      _isSubmitting = true; // Currently sending the id
      _submitError = null;
    });

    final response =
    await _skillService.selectSkills(_selectedSkillIds.toList());

    final data = jsonDecode(response.body);

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200) {
      await StorageService.saveNextScreen("worker_dashboard");
      if (!mounted) return; //This is a safety check that the screen is still active before navigating. Mounted = true means screen is active. 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TechnicianHomeScreen(),
        ),
      );

      return;
    }

    if (response.statusCode == 400) {
      setState(() {
        _submitError = data["skills"]?[0]; //"If data["skills"] is not null, give me the first item. Otherwise, return null."
      });

      return;
    }

    setState(() {
      _submitError = "Something went wrong.";
    });
  } //skill id send to backend
  Widget _buildHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Adaptive illustration visibility based on viewport dimensions
    final bool showIllustration = screenWidth > 400 && screenHeight > 500;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
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
            children: [
              Expanded(
                flex: 3,
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

                    const SizedBox(height: 6),

                    Text(
                      "Choose all the services you are skilled in.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    )
                  ],
                ),
              ),

              if (showIllustration) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Image.asset(
                    "assets/images/temple(skill).png",
                    fit: BoxFit.contain,
                  ),
                ),
              ],
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

    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth >= 900) {
      crossAxisCount = 5;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        itemCount: _filteredSkills.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final skill = _filteredSkills[index];
          final isSelected = _selectedSkillIds.contains(skill.id);
          final isDisabled = _selectedSkillIds.length >= 3 && !isSelected;

          return SkillCard(
            skill: skill,
            isSelected: isSelected,
            isDisabled: isDisabled,
            onTap: () {
              setState(() {
                if (_selectedSkillIds.contains(skill.id)) {
                  _selectedSkillIds.remove(skill.id);
                } else {
                  if (_selectedSkillIds.length >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You can select a maximum of 3 skills.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
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
            if (_selectedSkillIds.isNotEmpty) _buildSelectedSkills(),

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