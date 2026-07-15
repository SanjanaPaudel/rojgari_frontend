import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import '../../widgets/skill_card.dart';

// ---------------------------------------------------------------------------
// Icon resolver — maps the backend's icon-path string to a Flutter IconData.
// Backend sends paths like "/media/Icons.plumbing"; we parse the filename part.
// Any unknown / null value falls back to Icons.handyman.
// ---------------------------------------------------------------------------

const _kIconMap = <String, IconData>{
  'Icons.plumbing': Icons.plumbing,
  'Icons.electric_bolt': Icons.electric_bolt,
  'Icons.local_florist_outlined': Icons.local_florist_outlined,
  'Icons.format_paint_outlined': Icons.format_paint_outlined,
  'Icons.handyman_outlined': Icons.handyman_outlined,
  'Icons.cleaning_services_outlined': Icons.cleaning_services_outlined,
  'Icons.build_outlined': Icons.build_outlined,
  'Icons.tv_outlined': Icons.tv_outlined,
  'Icons.ac_unit_outlined': Icons.ac_unit_outlined,
  'Icons.computer_outlined': Icons.computer_outlined,
  'Icons.eco_outlined': Icons.eco_outlined,
};

IconData _resolveIcon(String? iconPath) {
  if (iconPath == null || iconPath.trim().isEmpty) return Icons.handyman;
  final name = iconPath.split('/').last.trim(); // e.g. "Icons.plumbing"
  return _kIconMap[name] ?? Icons.handyman;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TechnicianSkillSelectionScreen extends StatefulWidget {
  const TechnicianSkillSelectionScreen({
    super.key,
    this.initiallySelected = const [],
  });

  /// Skill names already selected by this technician (from the dashboard API).
  /// Used only to pre-highlight cards on load; matching is done by name.
  final List<String> initiallySelected;

  @override
  State<TechnicianSkillSelectionScreen> createState() =>
      _TechnicianSkillSelectionScreenState();
}

class _TechnicianSkillSelectionScreenState
    extends State<TechnicianSkillSelectionScreen> {
  final SkillService _skillService = SkillService();

  List<Skill> _allSkills = [];
  bool _isLoading = true;
  String? _loadError;

  final Set<int> _selectedSkillIds = {};
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final skills = await _skillService.getSkills();

      // Pre-select skills whose names are in the initiallySelected list.
      final preSelectedNames = widget.initiallySelected
          .map((n) => n.trim().toLowerCase())
          .toSet();

      final preSelectedIds = skills
          .where((s) => preSelectedNames.contains(s.name.trim().toLowerCase()))
          .map((s) => s.id)
          .toSet();

      setState(() {
        _allSkills = skills;
        _selectedSkillIds.addAll(preSelectedIds);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load skills. Please try again.';
      });
    }
  }

  // -------------------------------------------------------------------------
  // Toggle selection
  // -------------------------------------------------------------------------

  void _toggle(int skillId) {
    setState(() {
      _saveError = null;
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Save — POST selected IDs to backend, then pop with skill names
  // -------------------------------------------------------------------------

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final response =
          await _skillService.selectSkills(_selectedSkillIds.toList());

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Return the selected skill names so profile_screen can update its UI
        // without an additional API round-trip.
        final selectedNames = _allSkills
            .where((s) => _selectedSkillIds.contains(s.id))
            .map((s) => s.name)
            .toList();

        Navigator.pop(context, selectedNames);
        return;
      }

      setState(() {
        _isSaving = false;
        _saveError = 'Failed to save skills. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Something went wrong. Check your connection.';
      });
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFF),
        title: const Text(
          'Select Skills',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Info / count banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _selectedSkillIds.isEmpty
                      ? 'Choose the services you can confidently provide.'
                      : '${_selectedSkillIds.length} skill${_selectedSkillIds.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Skill grid ──────────────────────────────────────────────────
            Expanded(child: _buildGrid()),

            // ── Save error ──────────────────────────────────────────────────
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _saveError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Save button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton.icon(
                onPressed: _isSaving || _isLoading ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Save Skills'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grid body — handles loading / error / empty / data states
  // -------------------------------------------------------------------------

  Widget _buildGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadSkills,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allSkills.isEmpty) {
      return const Center(
        child: Text(
          'No skills available right now.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: _allSkills.length,
          itemBuilder: (context, index) {
            final skill = _allSkills[index];
            return SkillCard(
              skill: skill,
              isSelected: _selectedSkillIds.contains(skill.id),
              onTap: () => _toggle(skill.id),
              style: SkillCardStyle.technician,
              icon: _resolveIcon(skill.icon),
            );
          },
        );
      },
    );
  }
}
