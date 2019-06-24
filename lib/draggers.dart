import 'dart:async';

import 'package:flutter/material.dart';


class HorizontalDragger extends StatefulWidget {
  final StreamController<HorizontalDragUpdate> dragUpdateStream;

  HorizontalDragger({
    this.dragUpdateStream,
  });

  @override
  _HorizontalDraggerState createState() => _HorizontalDraggerState();
}

class _HorizontalDraggerState extends State<HorizontalDragger> {
  static const Full_Transition = 200.0;

  Offset dragStart;
  double slidePercent = 0.0;
  double startPercent;

  onDragStart(DragStartDetails details) {
    if (dragStart == null) {
      dragStart = details.globalPosition;
      startPercent = slidePercent;
    }
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dx = dragStart.dx - newPosition.dx;

      slidePercent = (dx / Full_Transition).clamp(-1.0, 1.0);

      slidePercent = (startPercent + slidePercent).clamp(0.0, 0.6);

      widget.dragUpdateStream.add(HorizontalDragUpdate(slidePercent));
    }
  }

  onDragEnd(DragEndDetails details) {
    dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: onDragStart,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
    );
  }
}

class VerticalDragger extends StatefulWidget {
  final StreamController<VerticalDragUpdate> verticalDragUpdateStream;

  VerticalDragger({
    this.verticalDragUpdateStream,
  });

  @override
  _VerticalDraggerState createState() => _VerticalDraggerState();
}

class _VerticalDraggerState extends State<VerticalDragger> {
  static const Full_Transition = 45.0;

  Offset dragStart;
  double slidePercent = 0.0;

  onDragStart(DragStartDetails details) {
    if (dragStart == null) {
      dragStart = details.globalPosition;
    }
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dy = dragStart.dy - newPosition.dy;

      slidePercent = (dy / Full_Transition).clamp(-1.0, 1.0);

      widget.verticalDragUpdateStream
          .add(VerticalDragUpdate(slidePercent));
    }
  }

  onDragEnd(DragEndDetails details) {
    dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
    );
  }
}

class HorizontalDragUpdate {
  final double slidePercent;

  HorizontalDragUpdate(
    this.slidePercent,
  );
}

class VerticalDragUpdate {
  final double slidePercent;

  VerticalDragUpdate(
    this.slidePercent,
  );
}
