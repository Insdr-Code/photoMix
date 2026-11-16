enum ExportFormat {
  png(extension: 'png', mimeType: 'image/png'),
  jpg(extension: 'jpg', mimeType: 'image/jpeg');

  const ExportFormat({required this.extension, required this.mimeType});

  final String extension;
  final String mimeType;
}
