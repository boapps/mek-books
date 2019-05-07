import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';

class EReaderPage extends StatefulWidget {
  EReaderPage({Key key, this.bookPath }) : super(key: key);

  String bookPath;
  @override
  _EReaderPageState createState() => _EReaderPageState();
}

class _EReaderPageState extends State<EReaderPage> {

  String bookPath;
  String documentData = "";

  void initBook() async {
    bookPath = widget.bookPath;
    File file  = File(bookPath);
    documentData = file.readAsStringSync(encoding: Latin1Codec());
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initBook();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: new Text(bookPath),),
      body: new Container(
          child: Html(
            data: documentData,

          ),
      ),
    );
  }
}
