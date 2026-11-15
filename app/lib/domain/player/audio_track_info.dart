/// Audio metadata is scoped to the current source generation.
final class AudioTrackInfo {
  const AudioTrackInfo({
    required this.id,
    this.title,
    this.language,
    this.codec,
    this.channels,
    this.sampleRate,
    this.bitrate,
    this.isDefault,
  });

  final String id;
  final String? title;
  final String? language;
  final String? codec;
  final int? channels;
  final int? sampleRate;
  final int? bitrate;
  final bool? isDefault;

  String get label {
    if (id == 'auto') return 'Audio automático';
    if (id == 'no') return 'Audio desactivado';
    final String name = playbackLanguageLabel(language);
    final String? trackTitle = title?.trim();
    return trackTitle == null || trackTitle.isEmpty
        ? name
        : '$name · $trackTitle';
  }
}

String playbackLanguageLabel(String? language) {
  final String? code = language?.trim().toLowerCase().replaceAll('_', '-');
  return switch (code) {
    'es' || 'spa' || 'esp' => 'Español',
    'es-419' => 'Español latinoamericano',
    'en' || 'eng' => 'Inglés',
    'ja' || 'jpn' => 'Japonés',
    'pt' || 'por' => 'Portugués',
    'pt-br' => 'Portugués brasileño',
    'zh' || 'zho' || 'chi' => 'Chino',
    'zh-cn' || 'zh-hans' => 'Chino simplificado',
    'zh-tw' || 'zh-hant' => 'Chino tradicional',
    'ko' || 'kor' => 'Coreano',
    'fr' || 'fra' || 'fre' => 'Francés',
    'de' || 'deu' || 'ger' => 'Alemán',
    'it' || 'ita' => 'Italiano',
    'ru' || 'rus' => 'Ruso',
    'ar' || 'ara' => 'Árabe',
    'hi' || 'hin' => 'Hindi',
    null || '' || 'und' => 'Idioma desconocido',
    _ => code,
  };
}
