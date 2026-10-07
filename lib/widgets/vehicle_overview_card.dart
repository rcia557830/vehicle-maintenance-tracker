import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../utils/formatters.dart';

class VehicleOverviewCard extends StatelessWidget {
  const VehicleOverviewCard({
    super.key,
    required this.vehicle,
    required this.onUpdate,
  });
  final Vehicle vehicle;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xff11233a), Color(0xff16454c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxWidth >= 440;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.nickname,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '${vehicle.year} ${vehicle.make} ${vehicle.model}',
              style: const TextStyle(color: Color(0xffc5d9de), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xff294553),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xff42606b)),
              ),
              child: Text(
                vehicle.plateNumber,
                style: const TextStyle(
                  color: Color(0xffe4f1ef),
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xff76dbc0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SELECTED VEHICLE',
                  style: TextStyle(
                    color: Color(0xffa7d6d0),
                    fontSize: 10,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (roomy)
              Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 14),
                  const VehicleIllustration(width: 180, height: 105),
                ],
              )
            else
              details,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xff365a65)),
            ),
            Wrap(
              spacing: 24,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current odometer',
                      style: TextStyle(color: Color(0xffa7c5ce), fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      distance(vehicle.odometer, vehicle.unit),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                if (constraints.maxWidth < 330)
                  IconButton.filledTonal(
                    tooltip: 'Update reading',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xffd2f4e9),
                      foregroundColor: const Color(0xff123f3c),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onUpdate,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  )
                else
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffd2f4e9),
                      foregroundColor: const Color(0xff123f3c),
                    ),
                    onPressed: onUpdate,
                    icon: const Icon(Icons.speed_outlined, size: 18),
                    label: const Text('Update reading'),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// Decorative vehicle artwork, not an image of the user's actual vehicle.
class VehicleIllustration extends StatelessWidget {
  const VehicleIllustration({super.key, this.width = 240, this.height = 130});
  final double width, height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(width, height),
      painter: const _VehiclePainter(),
    ),
  );
}

class _VehiclePainter extends CustomPainter {
  const _VehiclePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 130);
    final paint = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(12, 101, 220, 12),
      paint..color = const Color(0x3310202c),
    );
    final body = Path()
      ..moveTo(17, 84)
      ..lineTo(24, 65)
      ..lineTo(56, 58)
      ..lineTo(84, 29)
      ..quadraticBezierTo(90, 24, 101, 24)
      ..lineTo(158, 26)
      ..quadraticBezierTo(167, 27, 174, 38)
      ..lineTo(191, 59)
      ..lineTo(218, 66)
      ..quadraticBezierTo(229, 69, 230, 83)
      ..lineTo(228, 96)
      ..lineTo(17, 96)
      ..close();
    canvas.drawPath(
      body,
      paint
        ..color = Colors.white
        ..shader = const LinearGradient(
          colors: [Color(0xffb7eee1), Color(0xff60aeac)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(17, 24, 213, 72)),
    );
    paint.shader = null;
    final windows = Path()
      ..moveTo(69, 56)
      ..lineTo(91, 33)
      ..lineTo(122, 33)
      ..lineTo(122, 56)
      ..close()
      ..moveTo(130, 33)
      ..lineTo(158, 35)
      ..lineTo(178, 57)
      ..lineTo(130, 56)
      ..close();
    canvas.drawPath(windows, paint..color = const Color(0xff204c59));
    canvas.drawLine(
      const Offset(128, 62),
      const Offset(128, 88),
      paint
        ..color = const Color(0xff4a898d)
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      const Offset(140, 66),
      const Offset(151, 66),
      paint
        ..color = const Color(0xff26545a)
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(207, 70, 19, 8),
        const Radius.circular(3),
      ),
      paint..color = const Color(0xffedfff6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 69, 7, 9),
        const Radius.circular(2),
      ),
      paint..color = const Color(0xffdd9f75),
    );
    for (final x in [58.0, 185.0]) {
      canvas.drawCircle(
        Offset(x, 96),
        19,
        paint..color = const Color(0xff132a37),
      );
      canvas.drawCircle(
        Offset(x, 96),
        11,
        paint..color = const Color(0xff85abb5),
      );
      canvas.drawCircle(
        Offset(x, 96),
        5,
        paint..color = const Color(0xff294755),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VehiclePainter oldDelegate) => false;
}
