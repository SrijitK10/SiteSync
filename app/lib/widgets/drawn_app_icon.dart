import 'package:flutter/material.dart';

enum DrawnAppIconKind { projects, dashboard, activity, pending, assistant }

class DrawnAppIcon extends StatelessWidget {
  final DrawnAppIconKind kind;
  final Color? color;
  final double? size;

  const DrawnAppIcon({super.key, required this.kind, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(
        painter: _DrawnAppIconPainter(kind: kind, color: resolvedColor),
      ),
    );
  }
}

class _DrawnAppIconPainter extends CustomPainter {
  final DrawnAppIconKind kind;
  final Color color;

  const _DrawnAppIconPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case DrawnAppIconKind.projects:
        _paintProjects(canvas, size);
        return;
      case DrawnAppIconKind.dashboard:
        _paintDashboard(canvas, size);
        return;
      case DrawnAppIconKind.activity:
        _paintActivity(canvas, size);
        return;
      case DrawnAppIconKind.pending:
        _paintPending(canvas, size);
        return;
      case DrawnAppIconKind.assistant:
        _paintAssistant(canvas, size);
        return;
    }
  }

  void _paintProjects(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    final building = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.64, h * 0.72),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(building, stroke);
    for (final x in [0.32, 0.5, 0.68]) {
      canvas.drawLine(Offset(w * x, h * 0.3), Offset(w * x, h * 0.33), stroke);
      canvas.drawLine(Offset(w * x, h * 0.5), Offset(w * x, h * 0.53), stroke);
    }
    canvas.drawLine(
      Offset(w * 0.5, h * 0.7),
      Offset(w * 0.5, h * 0.86),
      stroke,
    );
  }

  void _paintDashboard(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final radius = Radius.circular(w * 0.07);
    final bars = [
      Rect.fromLTWH(w * 0.18, h * 0.52, w * 0.14, h * 0.32),
      Rect.fromLTWH(w * 0.43, h * 0.32, w * 0.14, h * 0.52),
      Rect.fromLTWH(w * 0.68, h * 0.18, w * 0.14, h * 0.66),
    ];
    for (final bar in bars) {
      canvas.drawRRect(RRect.fromRectAndRadius(bar, radius), paint);
    }
  }

  void _paintActivity(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.shortestSide * 0.34;
    canvas.drawCircle(center, radius, stroke);
    canvas.drawLine(
      center,
      Offset(size.width * 0.5, size.height * 0.32),
      stroke,
    );
    canvas.drawLine(
      center,
      Offset(size.width * 0.64, size.height * 0.58),
      stroke,
    );
  }

  void _paintPending(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    for (final y in [0.28, 0.5, 0.72]) {
      canvas.drawLine(Offset(w * 0.38, h * y), Offset(w * 0.8, h * y), stroke);
    }
    canvas.drawLine(
      Offset(w * 0.2, h * 0.28),
      Offset(w * 0.26, h * 0.34),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.26, h * 0.34),
      Offset(w * 0.34, h * 0.2),
      stroke,
    );
    canvas.drawCircle(Offset(w * 0.27, h * 0.5), w * 0.03, stroke);
    canvas.drawCircle(Offset(w * 0.27, h * 0.72), w * 0.03, stroke);
  }

  void _paintAssistant(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Chat bubble with rounded corners
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.15, w * 0.72, h * 0.54),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(bubbleRect, stroke);

    // Speech tail
    final path = Path()
      ..moveTo(w * 0.32, h * 0.69)
      ..lineTo(w * 0.22, h * 0.85)
      ..lineTo(w * 0.44, h * 0.69);
    canvas.drawPath(path, stroke);

    // 3 smart dots inside bubble
    final dotRadius = w * 0.045;
    canvas.drawCircle(Offset(w * 0.35, h * 0.42), dotRadius, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.42), dotRadius, fill);
    canvas.drawCircle(Offset(w * 0.65, h * 0.42), dotRadius, fill);
  }

  @override
  bool shouldRepaint(covariant _DrawnAppIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
