import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';

import '../controllers/vault_controller.dart';

class VaultView extends GetView<VaultController> {
  const VaultView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Icon + title ──────────────────────────────────────────────
            Icon(
              Icons.lock_outline_rounded,
              size: 68.w,
              color: AppColors.iconPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter PIN',
              style: AppFonts.bold24.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 6-digit vault PIN',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 40),

            // ── PIN dots ─────────────────────────────────────────────────
            Obx(() => _PinDots(
                  enteredLength: controller.pin.value.length,
                  shakeNotifier: controller.shakeNotifier.value,
                  pinLength: 6,
                )),

            const Spacer(flex: 3),

            // ── Numpad ───────────────────────────────────────────────────
            Obx(() => _Numpad(
                  onKeyTap: controller.onKeyTap,
                  onBackspace: controller.onBackspace,
                  enabled: !controller.isLoading.value,
                )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN dots with shake animation
// ─────────────────────────────────────────────────────────────────────────────

class _PinDots extends StatefulWidget {
  final int enteredLength;
  final int shakeNotifier;
  final int pinLength;

  const _PinDots({
    required this.enteredLength,
    required this.shakeNotifier,
    required this.pinLength,
  });

  @override
  State<_PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<_PinDots> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastShakeNotifier = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: _ShakeCurve()),
    );
  }

  @override
  void didUpdateWidget(_PinDots old) {
    super.didUpdateWidget(old);
    if (widget.shakeNotifier != _lastShakeNotifier) {
      _lastShakeNotifier = widget.shakeNotifier;
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * 12, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.pinLength, (i) {
          final filled = i < widget.enteredLength;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: .5.w, color: Colors.white),
              color: filled ? AppColors.primary : AppColors.secondary,
            ),
          );
        }),
      ),
    );
  }
}

// Shake curve — left-right oscillation
class _ShakeCurve extends Curve {
  @override
  double transform(double t) => sin(t * pi * 4) * (1 - t);
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom numpad
// ─────────────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final bool enabled;

  const _Numpad({
    required this.onKeyTap,
    required this.onBackspace,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _numpadRow(context, ['1', '2', '3']),
          const SizedBox(height: 12),
          _numpadRow(context, ['4', '5', '6']),
          const SizedBox(height: 12),
          _numpadRow(context, ['7', '8', '9']),
          const SizedBox(height: 12),
          // Bottom row: empty | 0 | backspace
          Row(
            children: [
              const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              Expanded(child: _NumpadKey(label: '0', onTap: () => onKeyTap('0'), enabled: enabled)),
              const SizedBox(width: 12),
              Expanded(
                child: _NumpadKey(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numpadRow(BuildContext context, List<String> keys) {
    return Row(
      children: keys.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
            child: _NumpadKey(
              label: e.value,
              onTap: () => onKeyTap(e.value),
              enabled: enabled,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;

  const _NumpadKey({
    this.label,
    this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: scheme.primary.withOpacity(0.15),
        child: SizedBox(
          height: 64,
          child: Center(
            child: icon != null
                ? Icon(icon, color: scheme.onSurface, size: 22)
                : Text(
                    label!,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
