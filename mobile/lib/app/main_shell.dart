import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/demo/presentation/demo_mode_provider.dart';

class MainShell extends ConsumerWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTabChanged;

  const MainShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  static const _tabs = [
    (Icons.map_outlined, Icons.map_rounded, 'Peta'),
    (Icons.show_chart_rounded, Icons.show_chart_rounded, 'Ramai'),
    (Icons.add_rounded, Icons.add_rounded, 'Unggah'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Saya'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoModeProvider);
    final scheme = Theme.of(context).colorScheme;

    // The bar floats over the content; extendBody lets maps and photos run
    // underneath, and adds the bar's height to the body's bottom padding.
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (demo)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Glass(
                  radius: 12,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      'Mode demo · data lokal · foto © Tomorrow',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ),
              ),
            _Glass(
              radius: 30,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, (icon, activeIcon, label)) in _tabs.indexed)
                      _Tab(
                        icon: i == currentIndex ? activeIcon : icon,
                        label: label,
                        selected: i == currentIndex,
                        scheme: scheme,
                        onTap: () => onTabChanged(i),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent blurred pill: the bar sits over maps and photos, so the
/// content stays readable through it.
class _Glass extends StatelessWidget {
  const _Glass({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ColoredBox(
            color: scheme.surfaceContainer.withValues(alpha: 0.82),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 12),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              if (selected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
