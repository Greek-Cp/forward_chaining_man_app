import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:forward_chaining_man_app/app/views/page_intro.dart';
import 'package:forward_chaining_man_app/app/views/page_login.dart';
import 'package:forward_chaining_man_app/app/views/page_profile.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

class ForwardChainingDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Define colors
    final workingMemoryColor = Colors.blue.shade100;
    final rulesColor = Colors.orange.shade100;
    final resultsColor = Colors.green.shade100;
    final arrowColor = Colors.grey.shade700;

    // Define paint objects
    final boxPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;

    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    // Helper function to draw boxes with text
    void drawBox(String title, String content, Rect rect, Color color) {
      // Draw box
      boxPaint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        boxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        borderPaint,
      );

      // Draw title
      final titleSpan = TextSpan(text: title, style: titleStyle);
      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
      );
      titlePainter.layout(maxWidth: rect.width - 10);
      titlePainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top + 5),
      );

      // Draw content
      final contentSpan = TextSpan(text: content, style: textStyle);
      final contentPainter = TextPainter(
        text: contentSpan,
        textDirection: TextDirection.ltr,
      );
      contentPainter.layout(maxWidth: rect.width - 10);
      contentPainter.paint(
        canvas,
        Offset(rect.left + 5, rect.top + 25),
      );
    }

    // Helper to draw arrows
    void drawArrow(Offset start, Offset end) {
      final paint = Paint()
        ..color = arrowColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw line
      canvas.drawLine(start, end, paint);

      // Draw arrowhead
      final delta = end - start;
      final angle = delta.direction;
      final arrowSize = 8.0;

      final arrowPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * math.cos(angle - math.pi / 6),
          end.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..lineTo(
          end.dx - arrowSize * math.cos(angle + math.pi / 6),
          end.dy - arrowSize * math.sin(angle + math.pi / 6),
        )
        ..close();

      canvas.drawPath(arrowPath, Paint()..color = arrowColor);
    }

    // Calculate box positions
    final workingMemoryRect = Rect.fromLTWH(20, 20, width * 0.25, height - 40);
    final rulesRect =
        Rect.fromLTWH(width * 0.33, 20, width * 0.25, height - 40);
    final resultsRect =
        Rect.fromLTWH(width * 0.66, 20, width * 0.25, height - 40);

    // Draw the boxes
    drawBox(
      'Working Memory',
      'Facts:\n• Q1=Yes\n• Q2=No\n• Q3=Yes\n...',
      workingMemoryRect,
      workingMemoryColor,
    );

    drawBox(
      'Rules',
      'IF Q1=Yes THEN Skor+3\nIF Q2=Yes THEN Skor+2\nIF Q3=Yes AND Q4=Yes\n THEN Skor+4\n...',
      rulesRect,
      rulesColor,
    );

    drawBox(
      'Results (Top 3)',
      '1. IPA | Kedokteran (24)\n2. IPS | Ekonomi (19)\n3. IPA | Teknik (16)',
      resultsRect,
      resultsColor,
    );

    // Draw arrows
    drawArrow(
      Offset(workingMemoryRect.right, workingMemoryRect.center.dy - 20),
      Offset(rulesRect.left, rulesRect.center.dy - 20),
    );

    drawArrow(
      Offset(rulesRect.right, rulesRect.center.dy),
      Offset(resultsRect.left, resultsRect.center.dy),
    );

    // Draw loop arrow for rule evaluation
    final loopStart = Offset(rulesRect.right - 20, rulesRect.bottom - 25);
    final loopControl1 = Offset(rulesRect.right + 20, rulesRect.bottom + 15);
    final loopControl2 = Offset(rulesRect.left - 20, rulesRect.bottom + 15);
    final loopEnd = Offset(rulesRect.left, rulesRect.bottom - 25);

    final loopPath = Path()
      ..moveTo(loopStart.dx, loopStart.dy)
      ..cubicTo(
        loopControl1.dx,
        loopControl1.dy,
        loopControl2.dx,
        loopControl2.dy,
        loopEnd.dx,
        loopEnd.dy,
      );

    canvas.drawPath(
      loopPath,
      Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Draw arrowhead for loop
    final loopDelta = Offset(0, -5);
    final loopAngle = loopDelta.direction;
    final arrowSize = 7.0;

    final loopArrowPath = Path()
      ..moveTo(loopEnd.dx, loopEnd.dy)
      ..lineTo(
        loopEnd.dx - arrowSize * math.cos(loopAngle - math.pi / 6),
        loopEnd.dy - arrowSize * math.sin(loopAngle - math.pi / 6),
      )
      ..lineTo(
        loopEnd.dx - arrowSize * math.cos(loopAngle + math.pi / 6),
        loopEnd.dy - arrowSize * math.sin(loopAngle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(loopArrowPath, Paint()..color = arrowColor);

    // Add "Rule Evaluation Loop" text
    final loopTextSpan = TextSpan(
      text: "Rule Evaluation Loop",
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 9,
        fontStyle: FontStyle.italic,
      ),
    );

    final loopTextPainter = TextPainter(
      text: loopTextSpan,
      textDirection: TextDirection.ltr,
    );
    loopTextPainter.layout();
    loopTextPainter.paint(
        canvas, Offset(rulesRect.center.dx - 35, rulesRect.bottom + 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
