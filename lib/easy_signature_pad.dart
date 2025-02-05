library signature_pad;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:easy_signature_pad/src/models/drawing_area.dart';
import 'package:easy_signature_pad/src/utils/drawing_area.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class EasySignaturePad extends StatefulWidget {
  /// callback function to be called on each drawing end
  final ValueChanged<String> onChanged;

  /// height of the canvas. Default = 256
  final int height;

  /// width of the canvas. Default = 400
  final int width;

  /// drawing pen/stroke color. Default = Colors.black
  final Color penColor;

  /// Pen/stroke width. Default = 2.0
  final double strokeWidth;

  /// canvas container border radius. Default = 10
  final double borderRadius;

  /// border color. Default = Colors.white
  final Color borderColor;

  /// signarure pad and image background color. Default = Colors.white
  final Color backgroundColor;

  /// creates the transaparent signature pad. Default = false
  final bool transparentSignaturePad;

  /// creates the transaparent image. Default = false
  final bool transparentImage;

  EasySignaturePad({
    Key? key,
    required this.onChanged,
    this.height = 256,
    this.width = 400,
    this.penColor = Colors.black,
    this.strokeWidth = 2.0,
    this.borderRadius = 5,
    this.borderColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.transparentSignaturePad = false,
    this.transparentImage = false,
  }) : super(key: key);

  @override
  _EasySignaturePadState createState() => _EasySignaturePadState();
}

class _EasySignaturePadState extends State<EasySignaturePad> {
  /// initialization of drawing points
  final List<DrawingArea> points = [];

  /// convert the points to base64 image. If no points (canvas is cleared), return null
  Future<String> saveToImage(List<DrawingArea> points) async {
    if (points.length < 1) return '';
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          Offset(0.0, 0.0),
          Offset(widget.width.toDouble(), widget.height.toDouble()),
        ));
    Paint paint = Paint()
      ..color = widget.penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = widget.strokeWidth;
    //background
    final paint2 = paint
      ..style = PaintingStyle.fill
      ..color =
          widget.transparentImage ? Colors.transparent : widget.backgroundColor;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, widget.width.toDouble(), widget.height.toDouble()),
        paint2);

    /// an algorithm to draw the points in the canvas
    for (int x = 0; x < points.length - 1; x++) {
      if (points[x].point.isFinite && points[x + 1].point.isFinite) {
        canvas.drawLine(
            points[x].point, points[x + 1].point, points[x].areaPaint);
      } else if (points[x].point.isFinite && !points[x + 1].point.isFinite) {
        canvas.drawPoints(
            PointMode.points, [points[x].point], points[x].areaPaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(widget.width, widget.height);

    /// converting to png
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes != null) {
      final listBytes = Uint8List.view(pngBytes.buffer);
      String b64Image = base64Encode(listBytes);
      return b64Image;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Container(
          width: widget.width.toDouble(),
          height: widget.height.toDouble(),
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.all(
              Radius.circular(widget.borderRadius),
            ),
          ),
          child: GestureDetector(
            onPanDown: (details) {
              this.setState(() {
                points.add(
                  DrawingArea(
                    point: details.localPosition,
                    areaPaint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = widget.penColor
                      ..strokeWidth = widget.strokeWidth,
                  ),
                );
              });
            },
            onPanUpdate: (details) {
              this.setState(() {
                points.add(
                  DrawingArea(
                    point: details.localPosition,
                    areaPaint: Paint()
                      ..strokeCap = StrokeCap.round
                      ..isAntiAlias = true
                      ..color = widget.penColor
                      ..strokeWidth = widget.strokeWidth,
                  ),
                );
              });
            },
            onPanEnd: (details) async {
              this.setState(() {
                points.add(DrawingArea(
                    point: Offset(double.infinity, double.infinity),
                    areaPaint: Paint()));
              });
              widget.onChanged(await saveToImage(points));
            },
            child: Stack(
              children: [
                SizedBox.expand(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(widget.borderRadius),
                    ),
                    child: CustomPaint(
                      painter: MyCustomPainter(
                        points: points,
                        transparent: widget.transparentSignaturePad,
                        backgroundColor: widget.backgroundColor,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        points.clear();
                      });
                      widget.onChanged(await saveToImage(points));
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(widget.borderRadius),
                        ),
                      ),
                      child: Icon(Icons.clear),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
