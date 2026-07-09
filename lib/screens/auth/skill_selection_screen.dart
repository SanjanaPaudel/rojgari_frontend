import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import 'package:rojgari_frontend_one/widgets/skill_card.dart';

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
  String? _errorMessage;

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
      final skills = await _skillService.getSkills();

      setState(() {
        _allSkills = skills;
        _filteredSkills = skills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load skills.";
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
      _errorMessage = null;
    });

    final error =
    await _skillService.selectSkills(_selectedSkillIds.toList());

    setState(() {
      _isSubmitting = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    // TODO: Navigate to Worker Dashboard
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            "Select Your Skills",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2340),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Choose all the services you are skilled in.\n"
                "You can select multiple options.",
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
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
        decoration: InputDecoration(
          hintText: "Search skills...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        itemCount: _allSkills.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final skill = _allSkills[index];

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
  }
  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitSkills,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A5AE0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            "Continue",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
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

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
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