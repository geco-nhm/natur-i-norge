import 'package:flutter/material.dart';

class BetaBanner extends StatelessWidget {
  const BetaBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.blue,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(
          'Betaversjon',
          style: Theme.of(context)
              .textTheme
              .bodyText2
              ?.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}
