import 'package:flutter/material.dart';
import 'package:realtime_obj_detection/tflite/recognition.dart';

/// Individual bounding box
class BoxWidget extends StatelessWidget {
  final Recognition result;

  const BoxWidget({Key? key, required this.result}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color = Colors.primaries[
        (result.label.length + result.label.codeUnitAt(0) + result.id) %
            Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" " + result.score.toStringAsFixed(2)),
                  Text(" Width: " +
                      result.renderLocation.width.ceil().toString()),
                  Column(
                    children: [
                      Text("Height : " +
                          result.renderLocation.height.ceil().toString()),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
