import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'Book.dart';
import 'DownloadManager.dart';

class DownloadsPage extends StatefulWidget {
  DownloadsPage({Key key}) : super(key: key);

  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<Book> books = new List();
  @override
  void initState() {
    super.initState();
    getDLs();
  }

  void getDLs() async {
    books = await DownloadManger().getDlBooks();
    setState(() {});
  }

  List<String> downloads = new List();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: new Text("Letöltések"),),
      body: new Container(
        child: new ListView.builder(itemBuilder: (BuildContext context, int n) {
          return new ListTile(
            leading: new Container(child: new Text(books[n].dlFormat, style: TextStyle(color: Colors.blue),), alignment: Alignment(0, 0),width: 40,),
            title: Text(
              books[n].title,
            ),
            subtitle: new Text(books[n].author??""),
            onTap: () {
              return showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return new FileDialog(books[n]);
                },
              ) ??
                  false;
            },
            trailing: new IconButton(icon: Icon(Icons.delete, ), onPressed: () async {
              _deleteConfirmDialog(context).then((ConfirmAction confirm) async {
                if (confirm == ConfirmAction.YES){
                  await DownloadManger().removeDLBook(books[n]);
                  books = await DownloadManger().getDlBooks();
                  setState(() {});
                }
              });
            }),
          );
        },
          itemCount: books.length,
        ),
      ),
    );
  }
}

enum ConfirmAction { CANCEL, YES }

Future<ConfirmAction> _deleteConfirmDialog(BuildContext context) async {
  return showDialog<ConfirmAction>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Biztos?"),
        content: const Text("Biztos törlöd ezt a könyvet?"),
        actions: <Widget>[
          FlatButton(
            child: const Text("Mégse"),
            onPressed: () {
              Navigator.of(context).pop(ConfirmAction.CANCEL);
            },
          ),
          FlatButton(
            child: const Text("Igen"),
            onPressed: () {
              Navigator.of(context).pop(ConfirmAction.YES);
            },
          )
        ],
      );
    },
  );
}

class FileDialog extends StatefulWidget {
  Book book;
  FileDialog(this.book);

  @override
  FileDialogState createState() => new FileDialogState();
}

class FileDialogState extends State<FileDialog> {
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
                children: [this.widget.book.dlFormat??""].map<Widget>((String format) {
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
              onPressed: () async {
                print(await this.widget.book.path);
                OpenFile.open(await this.widget.book.path);
              },
              child: new Text(
                "megnyit mással",
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
