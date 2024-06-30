class News {
  final String id;
  final String descripcion;
  final String edificio;
  final String fecha;
  final List<String> filesLinks;
  final List<String> filesNames;
  final String noticia;

  News({
    required this.id,
    required this.descripcion,
    required this.edificio,
    required this.fecha,
    required this.filesLinks,
    required this.filesNames,
    required this.noticia,
  });
}
