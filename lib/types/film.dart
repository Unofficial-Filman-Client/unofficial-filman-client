class Film {
  final String title;
  final String? desc;
  final String imageUrl;
  final String link;

  Film({
    required this.title,
    this.desc,
    required this.imageUrl,
    required this.link,
  });

  @override
  String toString() {
    return "Film(title: $title, desc: $desc, imageUrl: $imageUrl, link: $link)";
  }
}
