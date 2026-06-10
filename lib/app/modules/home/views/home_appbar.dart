// Patch: replace the entire GetBuilder<HomeController> app bar block
// in home_view.dart with this widget.
//
// Usage in HomeView.build Column:
//   _HomeAppBar(),  ← replaces the existing GetBuilder app bar block

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _anim.forward() : _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // final controller = Get.find<HomeController>();

    return GetBuilder<HomeController>(
      builder: (controller) {
        final isPrivate = controller.selectedVault.value.id != 'public';

        return SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              // subtle red bottom border when vault active
              border: Border(
                bottom: BorderSide(
                  color: isPrivate ? Colors.red : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
            child: Row(
              children: [
                // ── Vault icon ────────────────────────────────────────────
                GestureDetector(
                  onTap: controller.onVaultTapped,
                  child: Obx(() => Icon(
                        controller.selectedVault.value.id != 'public'
                            ? Icons.security_rounded
                            : Icons.view_in_ar_outlined,
                        size: 20.w,
                        color: controller.selectedVault.value.id != 'public' ? Colors.red : AppColors.primary,
                      )),
                ),

                12.horizontalSpace,

                // ── Title ─────────────────────────────────────────────────
                GestureDetector(
                  onTap: controller.getImages,
                  child: Obx(() => Text(
                        controller.selectedVault.value.id != 'public'
                            ? controller.selectedVault.value.name ?? 'mY Gallery'
                            : 'mY Gallery',
                        style: AppFonts.bold18.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      )),
                ),

                const Spacer(),

                // ── Slide-in actions ──────────────────────────────────────
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tag toggle
                      Transform.translate(
                        offset: Offset(_slideAnim.value * 2, 0),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Obx(() => GestureDetector(
                                onTap: () => controller.isGrouped.toggle(),
                                child: Icon(
                                  controller.isGrouped.value ? Icons.tag : Icons.tag_rounded,
                                  size: 20.w,
                                  color: controller.isGrouped.value ? AppColors.appBarIcon : AppColors.iconPrimary,
                                ),
                              )),
                        ),
                      ),

                      if (_expanded) 16.horizontalSpace,

                      // Settings
                      Transform.translate(
                        offset: Offset(_slideAnim.value, 0),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: GestureDetector(
                            onTap: controller.onSettingTapped,
                            child: Icon(
                              Icons.settings_outlined,
                              size: 20.w,
                              color: AppColors.iconPrimary,
                            ),
                          ),
                        ),
                      ),

                      // Close vault — only when secret vault active
                      if (isPrivate) ...[
                        if (_expanded) 16.horizontalSpace,
                        Transform.translate(
                          offset: Offset(_slideAnim.value * 0.5, 0),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: GestureDetector(
                              onTap: controller.onCloseVaultTapped,
                              child: Icon(
                                Icons.exit_to_app,
                                size: 20.w,
                                color: Colors.red.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ],

                      16.horizontalSpace,
                    ],
                  ),
                ),

                // ── Toggle button ⋮ / ✕ ──────────────────────────────────
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('close')
                          ? Tween(begin: 0.0, end: 0.0).animate(anim)
                          : Tween(begin: 0.125, end: 0.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _expanded
                        ? Icon(Icons.close, key: const ValueKey('close'), size: 20.w, color: AppColors.appBarIcon)
                        : Icon(Icons.more_vert_rounded,
                            key: const ValueKey('more'), size: 20.w, color: AppColors.appBarIcon),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
