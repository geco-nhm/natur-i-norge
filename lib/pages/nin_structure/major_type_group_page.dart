import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type_group/major_type_group_selector.dart';

class MajorTypeGroupPage extends StatelessWidget {
  const MajorTypeGroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => !route.navigator!.canPop()))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListView(
          children: [
            MajorTypeGroupSelector(),
          ],
        ),
      ),
    );
  }
}
