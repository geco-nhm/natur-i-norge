import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/minor_type_block.dart';

class MinorTypeDescription extends StatefulWidget {
  final MinorTypeBlock? minorTypeBlock;

  const MinorTypeDescription({Key? key, this.minorTypeBlock}) : super(key: key);

  @override
  _MinorTypeDescriptionState createState() => _MinorTypeDescriptionState();
}

class _MinorTypeDescriptionState extends State<MinorTypeDescription>
    with SingleTickerProviderStateMixin {
  int selected = 0;
  TabController? _controller;
  List<dynamic>? detailsList;

  @override
  void initState() {
    super.initState();
    var details = widget.minorTypeBlock!.minorTypeScaled!
                .detailedMinorTypesScaled!.length >
            0
        ? widget.minorTypeBlock!.minorTypeScaled!.detailedMinorTypesScaled
        : widget.minorTypeBlock!.minorTypeScaled!.minorTypes!
            .map((e) => e.minorType)
            .toList();
    detailsList = details;
    _controller = TabController(length: detailsList!.length, vsync: this);
    _controller!.addListener(() {
      if (_controller!.index != selected) {
        setState(() {
          selected = _controller!.index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var mt = detailsList![selected];

    var body = List<Widget>.empty(growable: true);
    body.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        mt.name,
        style: Theme.of(context).textTheme.headline4,
        textAlign: TextAlign.center,
      ),
    ));
    if (mt.description != null) {
      body.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          mt.description,
          style: Theme.of(context).textTheme.subtitle2,
          textAlign: TextAlign.center,
        ),
      ));
    }
    mt.other.forEach((key, value) {
      body.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.center,
        ),
      ));
      body.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value),
      ));
    });
    var tabs = detailsList!
        .map((e) => Tab(
              text: e.name,
            ))
        .toList();

    return Dialog(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
              stretch: true,
              title: Text(
                  widget.minorTypeBlock!.minorTypeScaled!.minorTypeScaledId!),
              bottom: detailsList!.length > 1
                  ? PreferredSize(
                      preferredSize: Size.fromHeight(50.0),
                      child: Container(
                        // width: 100,
                        child: TabBar(
                          controller: _controller,
                          // isScrollable: true,
                          tabs: tabs,
                        ),
                      ),
                    )
                  : null),
          SliverList(delegate: SliverChildListDelegate.fixed(body))
        ],
      ),

      // child: ListView(
      //   children: [
      //     // Text(minorType.name),
      //     // Text(minorType.description),
      //     // Text(minorType.other.toString())
      //   ],
      // ),
    );
  }
}
