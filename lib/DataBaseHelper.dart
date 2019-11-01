import 'package:http/http.dart';
import 'dart:async';
import 'dart:io';
import 'Book.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get dir async {
  return (await getApplicationDocumentsDirectory()).path;
}

Future<File> get dbFile async {
  return new File((await dir) + "/db.html");
}

Future<bool> downloadDB() async {
  try {
    String url = "http://www.mek.oszk.hu/export/mek2excel.htm";
    final response = await get(url);
    var data = response.body;
    await (await dbFile).writeAsString(data);
    return true;
  } catch (e) {
    print(e);
  }

  return false;
}

Future<bool> isDBOutdated() async {
  if ((await dbFile).existsSync())
    return (await dbFile).lastModifiedSync().isBefore(DateTime.now().subtract(Duration(days: 3)));
  return true;
}

Future<String> readDB() async {
  try {
    return (await dbFile).readAsString();
  } catch (e) {
    print(e);
    return "";
  }
}

Future<List<String>> autoComplete(String search) async {
  String data = await readDB();
  List<String> results = new List();
  int n = 0;

  for (String l in data.split("<tr>")) {
    if (n > 2) {
      String title = l.split("<td>")[3].replaceAll("<\/td>", "").trim();
      if (title.toLowerCase().contains(search)) {
        print(title);
        results.add(title);
      }
    }
    n++;
  }
  return results;
}

Future<List<Book>> searchDB(String search) async {
  String data = await readDB();
  List<Book> results = new List();
  int n = 0;
  print(data.split("<tr>").length);

  for (String l in data.split("<tr>")) {
    if (l.toLowerCase().contains(search)&&n>2) {
      try {
        int urlStart = l.indexOf("<a href=") + "<a href=".length;
        int urlEnd = l.indexOf(">", urlStart);
        String bUrl = l.substring(urlStart, urlEnd);

        int idStart = l.indexOf("MEK-") + "MEK-".length;
        int idEnd = l.indexOf("</a>", idStart);
        int id = int.parse(l.substring(idStart, idEnd));

        String author = l.split("<td>")[2].replaceAll("<\/td>", "").trim();
        String title = l.split("<td>")[3].replaceAll("<\/td>", "").trim();
        List<String> types = l.split("<td>")[4].replaceAll("<\/td>", "").replaceFirst("|","").split("|");
        types = types.map((String type)=>type.trim()).toList();
        List<String> themes = l.split("<td>")[5].replaceAll("<\/td>", "").replaceFirst("|","").split("|");
        themes = themes.map((String theme)=>theme.trim()).toList();
        List<String> tags =l.split("<td>")[6].replaceAll("<\/td>", "").replaceFirst("|","").split("|");
        tags = tags.map((String tag)=>tag.trim()).toList();
        List<String> languages = l.split("<td>")[7].replaceAll("<\/td>", "").replaceFirst("|","").split("|");
        languages = languages.map((String language)=>language.trim()).toList();
        List<String> formats = l.split("<td>")[8].replaceAll("<\/td>", "").replaceFirst("|","").split("|");
        formats = formats.map((String format)=>format.trim()).toList();
        formats.remove("PV");
        formats.remove("PVU");
        String date = l.split("<td>")[9].replaceAll("<\/td>", "").replaceAll("<\/tr>", "").trim();
        Book book = new Book(id, bUrl, author, title, types, themes, tags, languages, formats, date);

        results.add(book);
      } catch (e) {
        print(e);
      }
    }
    n++;
  }

  print("Könyvek száma: " + n.toString());
  return results;
}
