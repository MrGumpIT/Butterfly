import 'dart:async';
import 'dart:math';
import 'dart:ui' show Image;

import 'package:butterfly/models/area.dart';
import 'package:butterfly/models/document.dart';
import 'package:butterfly/models/element.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Image;

part 'path.dart';
part 'pen.dart';
part 'eraser.dart';
part 'label.dart';
part 'image.dart';

abstract class Renderer<T extends PadElement> {
  final T element;
  Area? area;

  Renderer(this.element);

  FutureOr<void> setup(AppDocument document) async => _updateArea(document);

  void _updateArea(AppDocument document) => area =
      document.areas.firstWhereOrNull((area) => area.rect.overlaps(rect));
  FutureOr<void> onAreaUpdate(AppDocument document) async =>
      _updateArea(document);
  Rect get rect;
  FutureOr<void> build(Canvas canvas, [bool foreground = false]);
  bool hit(Offset position, [double radius = 1]) =>
      rect.inflate(radius).contains(position);

  factory Renderer.fromElement(T element) {
    if (element is PenElement) {
      return PenRenderer(element) as Renderer<T>;
    }
    throw Exception('Invalid element type');
  }
}