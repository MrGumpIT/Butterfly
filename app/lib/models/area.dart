import 'dart:ui' as ui;

import 'package:butterfly/models/converter.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'area.g.dart';
part 'area.freezed.dart';

@freezed
class Area with _$Area {
  const Area._();
  const factory Area({
    @Default('') String name,
    required double width,
    required double height,
    @OffsetJsonConverter() required Offset position,
  }) = _Area;

  factory Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);
  // Aspect ratio is the ratio between width and height.
  factory Area.fromPoints(Offset first, Offset second,
      {double width = 0,
      double height = 0,
      double aspectRatio = 0,
      String name = ''}) {
    double realWidth = width;
    double realHeight = height;
    if (realWidth == 0) {
      realWidth = (second.dx - first.dx).abs();
    }
    if (realHeight == 0) {
      realHeight = (second.dy - first.dy).abs();
    }
    if (aspectRatio != 0 && height == 0) {
      realHeight = realWidth / aspectRatio;
    }
    if (aspectRatio != 0 && width == 0) {
      realWidth = realHeight * aspectRatio;
    }
    Offset position = Offset(
      first.dx > second.dx ? second.dx : first.dx,
      first.dy > second.dy ? second.dy : first.dy,
    );
    return Area(
        width: realWidth, height: realHeight, position: position, name: name);
  }

  Offset get second => Offset(position.dx + width, position.dy + height);

  bool hit(Offset offset) => rect.contains(offset);

  ui.Rect get rect {
    final topLeft = Offset(
      width < 0 ? position.dx + width : position.dx,
      height < 0 ? position.dy + height : position.dy,
    );
    return ui.Rect.fromLTWH(topLeft.dx, topLeft.dy, width.abs(), height.abs());
  }

  Area moveBy(Offset offset) => copyWith(position: position + offset);
}
