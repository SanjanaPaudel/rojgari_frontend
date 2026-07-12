import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ProTipCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ProTipCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xffF6F0FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffEFE6FF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -18,
                  child: Image.asset(
                    'assets/images/toolbox.png',
                    width: 175,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffEFE6FF),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          size: 27,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 62),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pro Tip',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Keep your profile updated and respond quickly to get more jobs.',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.25,
                                  color: Color(0xff5F6A8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
