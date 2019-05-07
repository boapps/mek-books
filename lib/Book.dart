class Book {
  int id;
  String url;
  String author;
  String title;
  List<String> types;
  List<String> themes;
  List<String> tags;
  List<String> languages;
  List<String> formats;
  String date;

  String path;
  String dlFormat;

  Book(this.id, this.url, this.author, this.title, this.types, this.themes, this.tags,
      this.languages, this.formats, this.date, {this.path});

  Book.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        url = json['url'],
        author = json['author'],
        title = json['title'],
        types = json['types'].toString().split(","),
        themes = json['themes'].toString().split(","),
        tags = json['tags'].toString().split(","),
        languages = json['languages'].toString().split(","),
        formats = json['formats'].toString().split(","),
        date = json['date'],
        path = json['path'],
        dlFormat = json['dlFormat'];

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'url': url,
        'author': author,
        'title': title,
        'types': types.join(","),
        'themes': themes.join(","),
        'tags': tags.join(","),
        'languages': languages.join(","),
        'formats': formats.join(","),
        'date': date,
        'path': path,
        'dlFormat': dlFormat,
      };
}
