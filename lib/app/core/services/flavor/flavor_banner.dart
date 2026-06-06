import 'package:flutter/material.dart';

class FlavorBanner extends StatelessWidget {
  final Widget child;
  final String flavor;

  const FlavorBanner({super.key, required this.child, required this.flavor});

  @override
  Widget build(BuildContext context) {
    if (flavor.toLowerCase() == 'prod') return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Banner(
        message: flavor.toUpperCase(),
        location: BannerLocation.topEnd,
        color: _colorForFlavor(flavor),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.2, letterSpacing: 1.0),
        child: child,
      ),
    );
  }

  Color _colorForFlavor(String flavor) {
    switch (flavor.toLowerCase()) {
      case 'dev':
        return Colors.red;
      case 'staging':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
