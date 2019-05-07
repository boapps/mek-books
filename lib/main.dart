import 'package:flutter/material.dart';
import 'DataBaseHelper.dart';
import 'Book.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:mek/DownloadsPage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'DownloadManager.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MekBooks',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        accentColor: Colors.orangeAccent,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  @override
  void initState() {
    super.initState();
    updateDB();
  }

  void updateDB() async {
    if (await isDBOutdated()) {
      Fluttertoast.showToast(
          msg: "Adatbázis frissítése",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.black45,
          textColor: Colors.white,
          fontSize: 16.0
      );
      downloadDB().then((bool success){
        Fluttertoast.showToast(
            msg: success ? "Sikeres frissítés":"Sikertelen",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIos: 1,
            backgroundColor: success ? Colors.green:Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      });
    }
  }

  List<Book> books = new List();

  bool isSearch = false;
  String searchTerm = "";
  double progress = 0;
  List<String> suggestions = new List();

  void search(String term) async {
    isSearch = true;
    setState(() {});
    books = await searchDB(term);
    isSearch = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MEK-books"),
        actions: <Widget>[
          new IconButton(icon: Icon(Icons.file_download), onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DownloadsPage()),
            );                //showSettingsDialog();

          }),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Container(
              child: progress != 0
                  ? new LinearProgressIndicator(
                      value: progress,
                    )
                  : new Container(),
              height: 2,
            ),
            new Container(
              padding: EdgeInsets.all(6),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      //suggestions: suggestions,
                      key: key,
                      onChanged: (String text) async {
                        //Api().getAutoComplete(text);
                        searchTerm = text;
                      },
                      onSubmitted: search,
                      /*textChanged: (String text) async {
                        //Api().getAutoComplete(text);
                        searchTerm = text;
                      },*/
                      //textSubmitted: search,
                      //clearOnSubmit: false,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.black),
                            gapPadding: 0),
                        contentPadding: EdgeInsets.all(8),
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  new IconButton(
                    color: Colors.orange,
                    icon: new Icon(Icons.search),
                    onPressed: () => search(searchTerm),
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.start,
              ),
            ),
            new Expanded(
              child: !isSearch ? new NotificationListener(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int n) {
                    return new ListTile(
                      leading: Image.network(books[n].url + "/borito.jpg"),
                      title: Text(
                        books[n].title,
                      ),
                      subtitle: Text(books[n].author),
                      trailing: books[n].formats.contains("MP3") ? Icon(Icons.hearing, color: Colors.green,) : Container(width: 0,),
                      onTap: () {
                        return showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return new BookDialog(books[n]);
                              },
                            ) ??
                            false;
                      },
                    );
                  },
                  itemCount: books.length,
                ),
              ):new Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadDialog extends StatefulWidget {
  Book book;
  DownloadDialog(this.book);

  @override
  DownloadDialogState createState() => new DownloadDialogState();
}

class DownloadDialogState extends State<DownloadDialog> {
  String selectedFormat = "";

  @override
  void initState() {
    setState(() {
      selectedFormat = this.widget.book.formats[0];
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    return new SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      title: new Text("Letöltés..."),
      children: <Widget>[
        new Center(
          child: selectedFormat != ""
              ? new Container(
                  child: new DropdownButton(
                    items: this.widget.book.formats.map((String format) {
                      return DropdownMenuItem(
                        child: Text(format),
                        value: format,
                      );
                    }).toList(),
                    value: selectedFormat,
                    onChanged: _onSelected,
                  ),
                )
              : Container(),
        ),
        new FlatButton(
          onPressed: () {
            print(selectedFormat);
            DownloadManger().downloadBook(this.widget.book, selectedFormat).then((bool success){
              Fluttertoast.showToast(
                  msg: success ? "Letöltés...":"Sikertelen letöltés",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIos: 1,
                  backgroundColor: success ? Colors.black45:Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
            });

          },
          child: new Text(
            "letöltés",
            style: TextStyle(color: Colors.blueAccent),
          ),
          padding: EdgeInsets.all(10),
        ),
      ],
    );
  }

  void _onSelected(String format) {
    setState(() {
      selectedFormat = format;
      print(format);
      print(selectedFormat);
    });
  }
}

class BookDialog extends StatefulWidget {
  Book book;
  BookDialog(this.book);

  @override
  BookDialogState createState() => new BookDialogState();
}

class BookDialogState extends State<BookDialog> {
  Widget build(BuildContext context) {
    return new SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      title: new Text(
        this.widget.book.title,
        textAlign: TextAlign.center,
      ),
      children: <Widget>[
        new Container(
          padding: EdgeInsets.all(10),
          height: 350,
          width: 200,
          child: new ListView(
            children: <Widget>[
              new Text(
                this.widget.book.author,
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              new Text(
                this.widget.book.date,
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              Wrap(
                children: this.widget.book.formats.map<Widget>((String format) {
                  return new Container(
                    child: Chip(
                      label: Text(
                        format,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.all(2),
                    ),
                    padding: EdgeInsets.only(left: 2, right: 2),
                  );
                }).toList(),
              ),
              Wrap(
                children:
                    this.widget.book.languages.map<Widget>((String format) {
                  return new Container(
                    child: Chip(
                      label: Text(
                        format,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.all(2),
                    ),
                    padding: EdgeInsets.only(left: 2, right: 2),
                  );
                }).toList(),
              ),
              Wrap(
                children: this.widget.book.tags.map<Widget>((String format) {
                  return new Container(
                    child: Chip(
                      label: Text(
                        format,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(2),
                    ),
                    padding: EdgeInsets.only(left: 2, right: 2),
                  );
                }).toList(),
              ),
              Wrap(
                children: this.widget.book.types.map<Widget>((String format) {
                  return new Container(
                    child: Chip(
                      label: Text(
                        format,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blueGrey,
                      padding: EdgeInsets.all(2),
                    ),
                    padding: EdgeInsets.only(left: 2, right: 2),
                  );
                }).toList(),
              ),
              Wrap(
                children: this.widget.book.themes.map<Widget>((String format) {
                  return new Container(
                    child: Chip(
                      label: Text(
                        format,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.all(2),
                    ),
                    padding: EdgeInsets.only(left: 2, right: 2),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new FlatButton(
              onPressed: () {
                return showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return new DownloadDialog(this.widget.book);
                      },
                    ) ??
                    false;
              },
              child: new Text(
                "letöltés",
                style: TextStyle(color: Colors.blueAccent),
              ),
              padding: EdgeInsets.all(2),
            ),
            new FlatButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: new Text(
                "mégse",
                style: TextStyle(color: Colors.blueAccent),
              ),
              padding: EdgeInsets.all(2),
            ),
          ],
        ),
      ],
    );
  }
}
