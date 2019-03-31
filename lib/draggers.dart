import 'dart:async';

import 'package:flutter/material.dart';

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  none,
}

class HorizontalDragger extends StatefulWidget {
  final StreamController<DragUpdate> dragUpdateStream;

  HorizontalDragger({
    this.dragUpdateStream,
  });

  @override
  _HorizontalDraggerState createState() => _HorizontalDraggerState();
}

class _HorizontalDraggerState extends State<HorizontalDragger> {
  static const Full_Transition = 200.0;

  Offset dragStart;
  SlideDirection slideDirection;
  double slidePercent = 0.0;
  double startPercent;

  onDragStart(DragStartDetails details) {
    if (dragStart == null) {
      dragStart = details.globalPosition;
      startPercent = slidePercent;
      //print('Heloo');
    }
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dx = dragStart.dx - newPosition.dx;
      if (dx > 0.0) {
        slideDirection = SlideDirection.rightToLeft;
      } else if (dx < 0.0) {
        slideDirection = SlideDirection.leftToRight;
      } else {
        slideDirection = SlideDirection.none;
      }

      slidePercent = (dx / Full_Transition).clamp(-1.0, 1.0);

      slidePercent = (startPercent + slidePercent).clamp(0.0, 0.6);

      widget.dragUpdateStream.add(DragUpdate(slideDirection, slidePercent));

      //print('Dragging $slideDirection at $slidePercent');

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
  SlideDirection slideDirection;
  double slidePercent = 0.0;
  //double startPercent;

  onDragStart(DragStartDetails details) {
    if (dragStart == null) {
      dragStart = details.globalPosition;
      //startPercent = slidePercent;
      //print('Heloo');
    }
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dy = dragStart.dy - newPosition.dy;
      if (dy > 0.0) {
        slideDirection = SlideDirection.topToBottom;
      } else if (dy < 0.0) {
        slideDirection = SlideDirection.bottomToTop;
      } else {
        slideDirection = SlideDirection.none;
      }

      slidePercent = (dy / Full_Transition).clamp(-1.0, 1.0);

      //slidePercent = (startPercent + slidePercent).clamp(0.0, 1.0);

      //print('Dragging $slideDirection at $slidePercent');

      widget.verticalDragUpdateStream
          .add(VerticalDragUpdate(slideDirection, slidePercent));
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

class DragUpdate {
  final direction;
  final slidePercent;

  DragUpdate(
    this.direction,
    this.slidePercent,
  );
}

class VerticalDragUpdate {
  final direction;
  final slidePercent;

  VerticalDragUpdate(
    this.direction,
    this.slidePercent,
  );
}
