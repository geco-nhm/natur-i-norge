import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class HomePageButton extends StatelessWidget {
  const HomePageButton(
      {Key? key,
      required this.image,
      required this.text,
      required this.onPressed})
      : super(key: key);
  final Image image;
  final String text;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Flex(
              direction: Axis.vertical,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: image),
                AutoSizeText(
                  text,
                  maxLines: 1,
                  wrapWords: false,
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.7,
                  // style: Theme.of(context).textTheme.headline3,
                )
              ],
            ),
          ),
        ),
        onPressed: onPressed as void Function()?,
      ),
    );
  }
}
