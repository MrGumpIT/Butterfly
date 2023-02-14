import 'colors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'property.g.dart';
part 'property.freezed.dart';

abstract class PathProperty implements Property {
  @override
  double get strokeWidth;
  double get thinning;
  double get smoothing;
  double get streamline;
}

@freezed
class Property with _$Property {
  @Implements<PathProperty>()
  const factory Property.pen({
    @Default(5) double strokeWidth,
    @Default(0.4) double thinning,
    @Default(kColorBlack) int color,
    @Default(false) bool fill,
    @Default(0.5) double smoothing,
    @Default(0.3) double streamline,
  }) = PenProperty;

  const factory Property.shape({
    @Default(5) double strokeWidth,
    required PathShape shape,
    @Default(kColorBlack) int color,
  }) = ShapeProperty;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

@freezed
class PathShape with _$PathShape {
  const PathShape._();
  const factory PathShape.circle({@Default(kColorTransparent) int fillColor}) =
      CircleShape;
  const factory PathShape.rectangle(
      {@Default(kColorTransparent) int fillColor,
      @Default(0) double topLeftCornerRadius,
      @Default(0) double topRightCornerRadius,
      @Default(0) double bottomLeftCornerRadius,
      @Default(0) double bottomRightCornerRadius}) = RectangleShape;
  const factory PathShape.line() = LineShape;

  factory PathShape.fromJson(Map<String, dynamic> json) =>
      _$PathShapeFromJson(json);
}
