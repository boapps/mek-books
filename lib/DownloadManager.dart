import 'dart:async';
import 'dart:io';
import 'Book.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';


class DownloadManger {

  Future<String> get downloadDirectoryPath async {
    Directory directory;
    try {
      directory = new Directory((await getExternalStorageDirectory()).path + "/mekbooks/");
      await directory.create();
    } catch (e) {
      print(e);
    }
    return directory.path;
  }

  Future<List<Book>> getDlBooks() async {
    List<Book> books = new List();
    try {
      File dlsFile = File((await getApplicationDocumentsDirectory()).path + "/" + "dls.json");
      if (dlsFile.existsSync()) {
        var jsonDownloads = json.decode(dlsFile.readAsStringSync());
        for (var jsonBook in jsonDownloads)
          books.add(Book.fromJson(jsonBook));
      }
    } catch (e) {
      print(e);
    }
    return books;
  }

  void saveDlBooks(List<Book> books) async {
    try {
      File dlsFile = File((await getApplicationDocumentsDirectory()).path + "/" + "dls.json");
      List<Map> dlsToSave = new List();
      for (Book book in books)
        dlsToSave.add(book.toJson());
      dlsFile.writeAsStringSync(json.encode(dlsToSave));
    } catch (e) {
      print(e);
    }
  }

  void removeDLBook(Book book) async {
    List<Book> books = await getDlBooks();
    books.removeWhere((Book b) => book.path == b.path);
    saveDlBooks(books);
    try {
      File bookFile = File(book.path);
      bookFile.delete();
    } catch (e) {
      print(e);
    }
  }

  Future<List<String>> getMP3Links(Book book) async {
    List<String> mp3Links = new List();
    var response = await get(book.url + "/mp3/index.html");
    var document = parse(response.body);
    var linkTable = document.getElementsByClassName("bor01").first;
    for (var li in linkTable.querySelector("ol").children)
      if (li.querySelector("a") != null)
        mp3Links.add(book.url.replaceFirst("http", "https") + "/mp3/" + li.querySelector("a").attributes["href"]);
    return mp3Links;
  }

  Future<bool> downloadBook(Book book, String format) async {
    bool success = true;
    if (format == "MP3") {
      for (String url in await getMP3Links(book)) {
        Map<PermissionGroup,
            PermissionStatus> permissions = await PermissionHandler()
            .requestPermissions([PermissionGroup.storage]);
        var dir = await downloadDirectoryPath + book.id.toString() + "/";
        String name = url.substring(url.indexOf("/mp3/") + 5);
        new Directory(dir).create().then((Directory value) async {
          await FlutterDownloader.enqueue(
            url: url,
            savedDir: dir,
            showNotification: true,
            openFileFromNotification: true,
            fileName: name,
          );
        });
        if(success){
          List<Book> books = await getDlBooks();
          book.path = dir + name;
          book.dlFormat = format;
          books.add(book);
          await saveDlBooks(books);
        }
      }
    } else {
      String url = linkFromFormat(format, book).replaceFirst("http", "https");
      Map<PermissionGroup,
          PermissionStatus> permissions = await PermissionHandler()
          .requestPermissions([PermissionGroup.storage]);
      var dir = await downloadDirectoryPath;
      String name = book.id.toString() + extensionFromFormat(format, book);
      try {
        new Directory(dir).create().then((Directory value) async {
          await FlutterDownloader.enqueue(
            url: url,
            savedDir: dir,
            showNotification: true,
            openFileFromNotification: true,
            fileName: name,
          );
          FlutterDownloader.registerCallback((String taskId, DownloadTaskStatus status, int percent) async {
            if (status == DownloadTaskStatus.complete){
              try {
                if (format == "HTML" || format == "TXT" || format == "XML"){
                  List<int> bytes = new File(dir + name).readAsBytesSync();
                  Archive archive = new ZipDecoder().decodeBytes(bytes);
                  for (ArchiveFile file in archive) {
                    extractFile(file, (await downloadDirectoryPath) + book.id.toString() + "_" + format);
                    if(file.name.contains(book.id.toString()) || file.name.contains("index"))
                      book.path = (await downloadDirectoryPath) + book.id.toString() + "_" + format + "/" + file.name;
                  }
                  File(dir + name).delete();
                  List<Book> books = await getDlBooks();
                  book.dlFormat = format;
                  books.add(book);
                  await saveDlBooks(books);
                }

              } catch (e) {
                print(e);
              }
              Fluttertoast.showToast(
                  msg: "Letöltés kész",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIos: 1,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
            }
          });
        });
      } catch (e) {
        success = false;
      }
      print(success);
      if (format!="HTML")
        if(success){
          List<Book> books = await getDlBooks();
          book.path = dir + name;
          book.dlFormat = format;
          books.add(book);
          await saveDlBooks(books);
        }
    }
    return success;
  }

  void extractFile(ArchiveFile file, String folder) async {
    String filename = file.name;
    if (file.isFile) {
      List<int> data = file.content;
      new File(folder + "/" + filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      new Directory(folder + "/" + filename)
        ..create(recursive: true);
    }
  }

  String linkFromFormat(String format, Book book) {
    print(format);
    if (format.contains("RTF"))
      return book.url + book.id.toString().padLeft(5, "0") + ".rtf";
    else if (format.contains("HTML"))
      return book.url + book.id.toString().padLeft(5, "0") + "html.zip";
    else if (format.contains("TXT"))
      return book.url + book.id.toString().padLeft(5, "0") + "txt.zip";
    else if (format.contains("PDF"))
      return book.url + book.id.toString().padLeft(5, "0") + ".pdf";
    else if (format.contains("WORD"))
      return book.url + book.id.toString().padLeft(5, "0") + ".doc";
    else if (format.contains("EPUB"))
      return book.url + book.id.toString().padLeft(5, "0") + ".epub";
    else if (format.contains("LIT"))
      return book.url + book.id.toString().padLeft(5, "0") + ".lit";
    else if (format.contains("PRC"))
      return book.url + book.id.toString().padLeft(5, "0") + ".prc";
    else if (format.contains("XML"))
      return book.url + book.id.toString().padLeft(5, "0") + "xml.zip";
    else if (format.contains("DjVu"))
      return book.url + book.id.toString().padLeft(5, "0") + ".djvu";
    else
      return book.url + book.id.toString().padLeft(5, "0") + "." + format.toLowerCase();
  }

  String extensionFromFormat(String format, Book book) {
    switch (format){
      case "RTF":
        return ".rtf";
      case "HTML":
        return "html.zip";
      case "TXT":
        return "txt.zip";
      case "PDF":
        return ".pdf";
      case "WORD":
        return ".doc";
      case "EPUB":
        return ".epub";
      case "LIT":
        return ".litz";
      case "PRC":
        return ".prc";
      case "XML":
        return "xml.zip";
      case "DjVu":
        return ".djvu";
      default:
        return "";
    }
  }

}