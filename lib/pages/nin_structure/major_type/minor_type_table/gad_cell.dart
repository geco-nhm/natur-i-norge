import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class GadCell extends StatelessWidget {
  final num? number;

  Color getShade(num number) {
    var x = 6 / number;
    return Colors.yellow.withOpacity(1 / x);
  }

  const GadCell({Key? key, this.number}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (number == null) {
      return Expanded(
        child: Container(
            // color: Colors.grey,
            ),
      );
    }
    return Expanded(
      child: Container(
        color: getShade(number!),
        child: Center(
          child: AutoSizeText(
            number!.toStringAsFixed(number!.truncateToDouble() == number ? 0 : 2),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
