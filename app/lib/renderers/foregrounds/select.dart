import 'dart:math';

import 'package:butterfly/cubits/transform.dart';
import 'package:butterfly/renderers/renderer.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

const cornerSize = 32.0;
const visibleSize = cornerSize / 2;

class LassoSelectionForegroundRenderer extends Renderer<List<Offset>> {
  final ColorScheme scheme;
  LassoSelectionForegroundRenderer(super.element, this.scheme);

  @override
  void build(Canvas canvas, Size size, NoteData document, DocumentPage page,
      DocumentInfo info, CameraTransform transform,
      [ColorScheme? colorScheme, bool foreground = false]) {
    final paint = Paint()
      ..color = scheme.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 / transform.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final fillPaint = Paint()
      ..color = scheme.primaryContainer.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.addPolygon(element, true);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }
}

typedef TransformResult = ({
  Offset position,
  double rotation,
  double scaleX,
  double scaleY
});

class RectSelectionForegroundManager {
  final bool enableRotation;
  Rect _selection = Rect.zero;
  SelectionScaleMode _scaleMode = SelectionScaleMode.scale;
  SelectionTransformCorner? _corner;
  Offset? _startPosition, _currentPosition;

  RectSelectionForegroundManager({this.enableRotation = true});

  Rect get selection => _selection;

  SelectionTransformCorner? get corner => _corner;

  void updateCurrentPosition(Offset position) {
    _currentPosition = position;
  }

  void updateCursor(double scale) {
    if (_currentPosition == null) return;
    _corner = getCornerHit(_currentPosition!, scale);
  }

  void resetTransform() {
    _scaleMode = SelectionScaleMode.scale;
    _corner = null;
    _startPosition = null;
    _currentPosition = null;
  }

  void select(Rect? selection) {
    _selection = selection ?? Rect.zero;
    resetTransform();
  }

  void deselect() => select(null);

  SelectionTransformCorner? getCornerHit(Offset position, double scale) {
    if (_selection.isEmpty) return null;
    final hits = SelectionTransformCorner.values.where((element) {
      final corner = element.getFromRect(_selection);
      if (element == SelectionTransformCorner.center && !enableRotation) {
        return false;
      }
      return Rect.fromCenter(
              center: corner,
              width: cornerSize / scale,
              height: cornerSize / scale)
          .contains(position);
    }).toList();
    if (hits.length == SelectionTransformCorner.values.length) return null;
    return hits.firstOrNull;
  }

  void toggleTransformMode() =>
      _scaleMode = (SelectionScaleMode.scale == _scaleMode
          ? SelectionScaleMode.scaleProp
          : SelectionScaleMode.scale);

  bool shouldTransform(Offset position, double scale) {
    return _selection.contains(position) ||
        getCornerHit(position, scale) != null;
  }

  bool startTransform(Offset position, double scale) {
    final hit = getCornerHit(position, scale);
    if (!_selection.contains(position) && hit == null) return false;
    _startPosition = position;
    _currentPosition = position;
    _corner = hit;
    return true;
  }

  void startTransformWithCorner(SelectionTransformCorner? corner) {
    _corner = corner;
    _startPosition = corner.getFromRect(_selection);
    _currentPosition = _startPosition;
  }

  bool get isTransforming => _startPosition != null;
  bool get isMoving => isTransforming && _corner == null;
  bool get isScaling => isTransforming && _corner != null;
  Offset get pivot => _selection.center;

  TransformResult? getTransform() {
    final position = _currentPosition;
    final previous = _startPosition;
    if (previous == position || position == null || previous == null) {
      return null;
    }
    final delta = position - previous;
    var scaleX = 1.0;
    var scaleY = 1.0;
    var moved = Offset.zero;
    var rotation = 0.0;
    switch (_corner) {
      case SelectionTransformCorner.topLeft:
        moved = delta;
        scaleX += -delta.dx / _selection.size.width;
        scaleY += -delta.dy / _selection.size.height;
      case SelectionTransformCorner.topCenter:
        scaleY += -delta.dy / _selection.size.height;
        moved = Offset(0, delta.dy);
      case SelectionTransformCorner.topRight:
        moved = Offset(0, delta.dy);
        scaleX += delta.dx / _selection.size.width;
        scaleY += -delta.dy / _selection.size.height;
      case SelectionTransformCorner.centerLeft:
        moved = Offset(delta.dx, 0);
        scaleX += -delta.dx / _selection.size.width;
        break;
      case SelectionTransformCorner.centerRight:
        scaleX += delta.dx / _selection.size.width;
      case SelectionTransformCorner.bottomLeft:
        moved = Offset(delta.dx, 0);
        scaleX += -delta.dx / _selection.size.width;
        scaleY += delta.dy / _selection.size.height;
      case SelectionTransformCorner.bottomCenter:
        scaleY += delta.dy / _selection.size.height;
      case SelectionTransformCorner.bottomRight:
        scaleX += delta.dx / _selection.size.width;
        scaleY += delta.dy / _selection.size.height;
      case SelectionTransformCorner.center when enableRotation:
        rotation = position.getRotation(_selection.center) / pi * 180;
      default:
        moved = delta;
    }
    if (_scaleMode == SelectionScaleMode.scaleProp) {
      final scale = max(scaleX, scaleY);
      scaleX = scale;
      scaleY = scale;
    }
    return (
      scaleX: scaleX,
      scaleY: scaleY,
      position: moved,
      rotation: rotation,
    );
  }

  void transform(SelectionScaleMode mode, SelectionTransformCorner corner) {
    _scaleMode = mode;
    _corner = corner;
  }

  RectSelectionForegroundRenderer get renderer =>
      RectSelectionForegroundRenderer(
          _selection, _scaleMode, _corner, enableRotation);
}

class RectSelectionForegroundRenderer extends Renderer<Rect> {
  final SelectionScaleMode? transformMode;
  final SelectionTransformCorner? transformCorner;
  final bool enableRotation;

  RectSelectionForegroundRenderer(super.element,
      [this.transformMode, this.transformCorner, this.enableRotation = true]);

  @override
  void build(Canvas canvas, Size size, NoteData document, DocumentPage page,
      DocumentInfo info, CameraTransform transform,
      [ColorScheme? colorScheme, bool foreground = false]) {
    if (element.isEmpty) return;
    final paint = Paint()
      ..color = colorScheme?.primaryContainer ?? Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 / transform.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawRect(element, paint);
    if (transformMode == null) return;
    final color = transformMode == SelectionScaleMode.scaleProp
        ? Colors.red
        : Colors.blue;
    final transformPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / transform.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final realSize = visibleSize / transform.size;
    if (element.width < 2 * realSize || element.height < 2 * realSize) return;
    final showCenter =
        element.width > 3 * realSize && element.height > 3 * realSize;
    SelectionTransformCorner.values
        .where((element) => !element.isCenter() || showCenter)
        .forEach((corner) {
      final position = corner.getFromRect(element);
      if (corner == SelectionTransformCorner.center) {
        canvas.drawCircle(
          position,
          realSize,
          transformPaint
            ..style = corner == transformCorner
                ? PaintingStyle.fill
                : PaintingStyle.stroke,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: position,
            width: realSize,
            height: realSize,
          ),
          transformPaint
            ..style = corner == transformCorner
                ? PaintingStyle.fill
                : PaintingStyle.stroke,
        );
      }
    });
  }
}

enum SelectionScaleMode { scale, scaleProp }

enum SelectionTransformCorner {
  // For rotating
  center,

  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

extension SelectionTransformCornerExtension on SelectionTransformCorner? {
  bool isCenter() => switch (this) {
        SelectionTransformCorner.topCenter ||
        SelectionTransformCorner.centerLeft ||
        SelectionTransformCorner.centerRight ||
        SelectionTransformCorner.bottomCenter =>
          true,
        _ => false,
      };

  Offset getFromRect(Rect rect) => switch (this) {
        SelectionTransformCorner.topLeft => rect.topLeft,
        SelectionTransformCorner.topCenter => rect.topCenter,
        SelectionTransformCorner.topRight => rect.topRight,
        SelectionTransformCorner.centerLeft => rect.centerLeft,
        SelectionTransformCorner.centerRight => rect.centerRight,
        SelectionTransformCorner.bottomLeft => rect.bottomLeft,
        SelectionTransformCorner.bottomCenter => rect.bottomCenter,
        SelectionTransformCorner.bottomRight => rect.bottomRight,
        _ => rect.center,
      };
}
