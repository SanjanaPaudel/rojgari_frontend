import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class TechnicianSkillOption {
  const TechnicianSkillOption(this.name, this.icon);
  final String name;
  final IconData icon;
}

const technicianSkillCatalog = <TechnicianSkillOption>[
  TechnicianSkillOption('Plumbing', Icons.plumbing),
  TechnicianSkillOption('Electrician', Icons.electric_bolt),
  TechnicianSkillOption('Gardening', Icons.eco_outlined),
  TechnicianSkillOption('Painting', Icons.format_paint_outlined),
  TechnicianSkillOption('Carpenter', Icons.handyman_outlined),
  TechnicianSkillOption('Mechanic', Icons.build_outlined),
  TechnicianSkillOption('Computer Repair', Icons.computer_outlined),
  TechnicianSkillOption('TV Repair', Icons.tv_outlined),
  TechnicianSkillOption('Maid/Cleaning', Icons.cleaning_services_outlined),
  TechnicianSkillOption('AC Repair', Icons.ac_unit_outlined),
];

class TechnicianSkillSelectionScreen extends StatefulWidget {
  const TechnicianSkillSelectionScreen({
    super.key,
    this.initiallySelected = const [],
  });

  final List<String> initiallySelected;

  @override
  State<TechnicianSkillSelectionScreen> createState() =>
      _TechnicianSkillSelectionScreenState();
}

class _TechnicianSkillSelectionScreenState
    extends State<TechnicianSkillSelectionScreen> {
  late final Set<String> _selected = widget.initiallySelected.toSet();

  void _toggle(String skill) {
    setState(() {
      _selected.contains(skill)
          ? _selected.remove(skill)
          : _selected.add(skill);
    });
  }

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
                  _selected.isEmpty
                      ? 'Choose the services you can confidently provide.'
                      : '${_selected.length} skill${_selected.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
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
                    itemCount: technicianSkillCatalog.length,
                    itemBuilder: (context, index) {
                      final skill = technicianSkillCatalog[index];
                      final selected = _selected.contains(skill.name);
                      return Semantics(
                        button: true,
                        selected: selected,
                        child: InkWell(
                          onTap: () => _toggle(skill.name),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.lightPurple
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFEEEAF9),
                                width: selected ? 1.5 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A231447),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.lightPurple,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        skill.icon,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        skill.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (selected)
                                  const Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 21,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _selected.toList()),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Skills'),
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
}

// BACKEND TODO: Use the same catalog and selected skill IDs returned by the
// technician signup flow once your friend's skill-selection screen is merged.
