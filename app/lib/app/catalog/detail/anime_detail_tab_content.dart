import 'package:anime_app/domain/catalog/anime_detail_metadata.dart';
import 'package:anime_app/domain/catalog/episode_index_provider.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:material_ui/material_ui.dart';

import 'anime_detail_tabs.dart';

final class AnimeDetailTabContent extends StatelessWidget {
  const AnimeDetailTabContent({
    required this.tab,
    required this.metadata,
    required this.progress,
    required this.canSaveProgress,
    required this.positionController,
    required this.saving,
    required this.error,
    required this.onSaveProgress,
    this.onCopyExternalEpisodeLink,
    this.onPlayEpisode,
    this.episodeIndex,
    this.episodeIndexLoading = false,
    this.episodeIndexError,
    this.onLoadMoreEpisodes,
    super.key,
  });

  final AnimeDetailTab tab;
  final ProviderAnimeMetadata? metadata;
  final PlaybackProgress? progress;
  final bool canSaveProgress;
  final TextEditingController positionController;
  final bool saving;
  final String? error;
  final VoidCallback onSaveProgress;
  final ValueChanged<Uri>? onCopyExternalEpisodeLink;
  final ValueChanged<int>? onPlayEpisode;
  final EpisodeIndexPage? episodeIndex;
  final bool episodeIndexLoading;
  final String? episodeIndexError;
  final VoidCallback? onLoadMoreEpisodes;

  @override
  Widget build(BuildContext context) => switch (tab) {
    AnimeDetailTab.episodes => _EpisodesTab(
      metadata: metadata,
      progress: progress,
      canSaveProgress: canSaveProgress,
      controller: positionController,
      saving: saving,
      error: error,
      onSave: onSaveProgress,
      onCopyExternalEpisodeLink: onCopyExternalEpisodeLink,
      onPlayEpisode: onPlayEpisode,
      episodeIndex: episodeIndex,
      episodeIndexLoading: episodeIndexLoading,
      episodeIndexError: episodeIndexError,
      onLoadMoreEpisodes: onLoadMoreEpisodes,
    ),
    AnimeDetailTab.information => _InformationTab(metadata: metadata),
    AnimeDetailTab.cast => _DetailTextList(
      storageKey: 'detail-cast',
      empty: 'No hay datos de reparto disponibles.',
      rows: [
        for (final character
            in metadata?.detail?.characters ?? const <AnimeCharacter>[])
          (
            character.name,
            character.voiceActors.map((actor) => actor.name).join(' · '),
          ),
      ],
    ),
    AnimeDetailTab.gallery => _GalleryTab(metadata: metadata),
    AnimeDetailTab.titles => _AlternativeTitlesTab(metadata: metadata),
    AnimeDetailTab.links => _DetailTextList(
      storageKey: 'detail-relations',
      empty: 'Todavía no hay relaciones verificadas disponibles.',
      rows: [
        for (final related
            in metadata?.detail?.relations ?? const <RelatedAnime>[])
          (related.title, related.relation ?? ''),
      ],
    ),
  };
}

final class _DetailTextList extends StatelessWidget {
  const _DetailTextList({
    required this.storageKey,
    required this.empty,
    required this.rows,
  });

  final String storageKey;
  final String empty;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _UnavailableTab(message: empty);
    return ListView.separated(
      key: PageStorageKey<String>(storageKey),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(color: Color(0xff242329)),
      itemBuilder: (context, index) {
        final (title, detail) = rows[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(detail.isEmpty ? title : '$title · $detail'),
        );
      },
    );
  }
}

final class _EpisodesTab extends StatelessWidget {
  const _EpisodesTab({
    required this.metadata,
    required this.progress,
    required this.canSaveProgress,
    required this.controller,
    required this.saving,
    required this.error,
    required this.onSave,
    required this.onCopyExternalEpisodeLink,
    required this.episodeIndex,
    required this.episodeIndexLoading,
    required this.episodeIndexError,
    required this.onLoadMoreEpisodes,
    this.onPlayEpisode,
  });
  final ProviderAnimeMetadata? metadata;
  final PlaybackProgress? progress;
  final bool canSaveProgress;
  final TextEditingController controller;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final ValueChanged<Uri>? onCopyExternalEpisodeLink;
  final ValueChanged<int>? onPlayEpisode;
  final EpisodeIndexPage? episodeIndex;
  final bool episodeIndexLoading;
  final String? episodeIndexError;
  final VoidCallback? onLoadMoreEpisodes;

  @override
  Widget build(BuildContext context) {
    final List<ProviderEpisodeMetadata> indexed =
        episodeIndex?.episodes ?? const [];
    final int? announced =
        metadata?.episodeCount ?? metadata?.detail?.episodeCount;
    final bool hasIndex = indexed.isNotEmpty;
    final List<AnimeEpisodeMetadata> externalEpisodes = [
      for (final AnimeEpisodeMetadata episode
          in metadata?.detail?.episodes ?? const <AnimeEpisodeMetadata>[])
        if (episode.externalWatchUri != null) episode,
    ];
    final String? caption = hasIndex
        ? '${indexed.length} de ${episodeIndex?.totalCount ?? indexed.length}'
              ' indexados · fuentes sin verificar'
        : announced != null && announced > 0
        ? '$announced anunciados (AniList) · sin índice'
        : null;

    return CustomScrollView(
      key: const PageStorageKey<String>('detail-episodes-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Row(
                  children: [
                    Text('Episodios', style: _sectionTitle(context)),
                    if (caption != null) ...[
                      const Spacer(),
                      Flexible(
                        child: Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xffaaa6af),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (externalEpisodes.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Ver en servicio externo',
                style: TextStyle(
                  color: Color(0xfff4f1f8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Enlaces legales publicados por AniList. Se abren fuera del reproductor de Kongroo.',
                style: TextStyle(color: Color(0xffaaa6af), fontSize: 13),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            sliver: SliverList.builder(
              itemCount: externalEpisodes.length,
              itemBuilder: (BuildContext context, int index) {
                final AnimeEpisodeMetadata episode = externalEpisodes[index];
                final Uri? uri = episode.externalWatchUri;
                if (uri == null) return const SizedBox.shrink();
                return _ExternalEpisodeLink(
                  episode: episode,
                  uri: uri,
                  index: index,
                  onCopy: onCopyExternalEpisodeLink,
                );
              },
            ),
          ),
        ],
        if (!hasIndex && episodeIndex?.hasMore != true)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EpisodeIndexStatus(
              loading: episodeIndexLoading,
              failed: episodeIndexError != null,
              announced: announced,
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.55,
              ),
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final ProviderEpisodeMetadata episode = indexed[index];
                final int number = episode.episodeNumber;
                return _EpisodeCard(
                  number: number,
                  title: episode.title,
                  thumbnailUrl: episode.thumbnailUrl,
                  onPlay: onPlayEpisode == null
                      ? null
                      : () => onPlayEpisode!(number),
                );
              }, childCount: indexed.length),
            ),
          ),
          if (episodeIndex?.hasMore == true && onLoadMoreEpisodes != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: OutlinedButton(
                    onPressed: episodeIndexLoading ? null : onLoadMoreEpisodes,
                    child: Text(
                      episodeIndexLoading
                          ? 'Cargando…'
                          : 'Cargar más episodios',
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: _ProgressEditor(
                    progress: progress,
                    canSaveProgress: canSaveProgress,
                    controller: controller,
                    saving: saving,
                    error: error,
                    onSave: onSave,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

final class _ExternalEpisodeLink extends StatelessWidget {
  const _ExternalEpisodeLink({
    required this.episode,
    required this.uri,
    required this.index,
    required this.onCopy,
  });

  final AnimeEpisodeMetadata episode;
  final Uri uri;
  final int index;
  final ValueChanged<Uri>? onCopy;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey<String>('external-streaming-link-$index'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(episode.site ?? uri.host),
    trailing: TextButton.icon(
      key: ValueKey<String>('copy-external-streaming-link-$index'),
      onPressed: onCopy == null ? null : () => onCopy!(uri),
      icon: const Icon(Icons.copy),
      label: const Text('Copiar enlace'),
    ),
  );
}

final class _EpisodeIndexStatus extends StatelessWidget {
  const _EpisodeIndexStatus({
    required this.loading,
    required this.failed,
    required this.announced,
  });

  final bool loading;
  final bool failed;
  final int? announced;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cargando episodios'),
      );
    }
    if (failed) {
      return const _UnavailableTab(
        message: 'No se pudo cargar el índice de episodios. Vuelve a intentarlo más tarde.',
      );
    }
    return _UnavailableTab(
      message: announced != null && announced! > 0
          ? 'AniList anuncia $announced episodios, pero no hay índice verificado.'
          : 'No hay episodios publicados para esta ficha.',
    );
  }
}

final class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.number,
    required this.title,
    required this.thumbnailUrl,
    this.onPlay,
  });

  final int number;
  final String? title;
  final String? thumbnailUrl;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final String? thumbnail = thumbnailUrl;
    final String? subtitle = _episodeSubtitle(title, number);
    return Semantics(
      key: ValueKey<String>('episode-card-$number'),
      label: subtitle == null
          ? 'Episodio $number'
          : 'Episodio $number, $subtitle',
      image: thumbnail != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff0d0d10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff242329)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox.expand(
                  child: thumbnail == null
                      ? ColoredBox(
                          color: const Color(0xff151419),
                          child: Center(
                            child: Text(
                              '$number',
                              style: const TextStyle(
                                color: Color(0xff8f8995),
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          cacheWidth: 480,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xff151419),
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xff8f8995),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 8, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Episodio $number',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (onPlay != null)
                          IconButton(
                            tooltip: 'Buscar fuentes del episodio',
                            visualDensity: VisualDensity.compact,
                            onPressed: onPlay,
                            icon: const Icon(Icons.play_arrow_rounded),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xffaaa6af),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProgressEditor extends StatelessWidget {
  const _ProgressEditor({
    required this.progress,
    required this.canSaveProgress,
    required this.controller,
    required this.saving,
    required this.error,
    required this.onSave,
  });

  final PlaybackProgress? progress;
  final bool canSaveProgress;
  final TextEditingController controller;
  final bool saving;
  final String? error;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (canSaveProgress) ...[
        TextField(
          key: const ValueKey('progress-seconds'),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Posición guardada (segundos)',
            helperText: 'El progreso local todavía no inicia una fuente de reproducción.',
          ),
        ),
        const SizedBox(height: 10),
        _QuietButton(
          key: const ValueKey('save-progress'),
          label: saving ? 'Guardando…' : 'Guardar progreso local',
          onPressed: saving ? null : onSave,
        ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Recuperado: ${progress!.positionMs ~/ 1000} segundos',
              key: const ValueKey('saved-progress-summary'),
              style: const TextStyle(color: Color(0xffcbc7d0)),
            ),
          ),
      ],
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );
}

String? _episodeSubtitle(String? title, int number) {
  if (title == null) return null;
  final String cleaned = title
      .replaceFirst(
        RegExp('^Episode\\s+$number\\s*[-:–—]?\\s*', caseSensitive: false),
        '',
      )
      .trim();
  return cleaned.isEmpty ? null : cleaned;
}

final class _InformationTab extends StatelessWidget {
  const _InformationTab({required this.metadata});
  final ProviderAnimeMetadata? metadata;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey<String>('detail-information-scroll'),
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata?.synopsis case final String synopsis) ...[
              Text('Sinopsis', style: _sectionTitle(context)),
              const SizedBox(height: 10),
              Text(
                synopsis,
                style: const TextStyle(
                  color: Color(0xffe1dee5),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text('Detalles', style: _sectionTitle(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                if (metadata?.format case final format?)
                  _Fact('Formato', _formatName(format)),
                if (metadata?.releaseYear case final year?)
                  _Fact('Emisión', _yearRange(year, metadata?.endYear)),
                if (metadata?.season case final season? when season.isNotEmpty)
                  _Fact('Temporada', _seasonName(season, metadata?.seasonYear)),
                if (metadata?.airingStatus case final status?)
                  _Fact('Estado', _statusName(status)),
                if (metadata?.averageScore case final score?)
                  _Fact('Puntuación', '$score%'),
                if (metadata?.detail case final detail?) ...[
                  if (detail.studios.isNotEmpty)
                    _Fact('Estudio', detail.studios.join(' · ')),
                  if (detail.trailer case final trailer?)
                    _Fact('Tráiler', trailer.site),
                ],
                if (metadata?.popularity case final popularity?)
                  _Fact('Popularidad', '$popularity'),
              ],
            ),
            if (metadata?.genres.isNotEmpty ?? false) ...[
              const SizedBox(height: 26),
              Text('Géneros', style: _sectionTitle(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metadata!.genres
                    .map((String value) => _GenrePill(value))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

final class _GalleryTab extends StatelessWidget {
  const _GalleryTab({required this.metadata});
  final ProviderAnimeMetadata? metadata;

  @override
  Widget build(BuildContext context) {
    final List<String> images = [
      metadata?.coverImageUrl,
      metadata?.bannerImageUrl,
    ].whereType<String>().toSet().toList(growable: false);
    if (images.isEmpty) {
      return const _UnavailableTab(
        key: ValueKey('detail-gallery-empty'),
        message: 'No hay imágenes disponibles para esta ficha.',
      );
    }
    final int decodeWidth = (MediaQuery.sizeOf(context).width * .8)
        .round()
        .clamp(320, 1200);
    return GridView.builder(
      key: const PageStorageKey<String>('detail-gallery-grid'),
      padding: const EdgeInsets.all(22),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 440,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.65,
      ),
      itemCount: images.length,
      itemBuilder: (BuildContext context, int index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          images[index],
          fit: BoxFit.cover,
          cacheWidth: decodeWidth,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xff101014),
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

final class _AlternativeTitlesTab extends StatelessWidget {
  const _AlternativeTitlesTab({required this.metadata});
  final ProviderAnimeMetadata? metadata;

  @override
  Widget build(BuildContext context) {
    final titles = <String>{
      if (metadata?.romajiTitle case final String title) title,
      ...?metadata?.alternativeTitles,
    }.where((String title) => title != metadata?.preferredTitle).toList();
    if (titles.isEmpty) {
      return const _UnavailableTab(
        key: ValueKey('detail-titles-empty'),
        message: 'No hay títulos alternativos disponibles.',
      );
    }
    return ListView.separated(
      key: const PageStorageKey<String>('detail-titles-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      itemCount: titles.length,
      separatorBuilder: (_, _) => const Divider(color: Color(0xff242329)),
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          titles[index],
          style: const TextStyle(color: Color(0xffe8e5ec), fontSize: 15),
        ),
      ),
    );
  }
}

final class _UnavailableTab extends StatelessWidget {
  const _UnavailableTab({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xffaaa6af)),
      ),
    ),
  );
}

final class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xffaaa6af), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Color(0xffe5e2e9), fontSize: 14),
        ),
      ],
    ),
  );
}

final class _GenrePill extends StatelessWidget {
  const _GenrePill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xff151519),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xffe7e4eb), fontSize: 13),
    ),
  );
}

final class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xffe8c9ff),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xff6e4b80)),
      ),
    ),
    child: Text(label),
  );
}

TextStyle? _sectionTitle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -.2,
    );

String _formatName(AnimeFormat value) => switch (value) {
  AnimeFormat.tv => 'Serie de TV',
  AnimeFormat.movie => 'Película',
  AnimeFormat.ova => 'OVA',
  AnimeFormat.ona => 'ONA',
  AnimeFormat.special => 'Especial',
  AnimeFormat.manga => 'Manga',
  AnimeFormat.unknown => 'No disponible',
};

String _statusName(AnimeAiringStatus value) => switch (value) {
  AnimeAiringStatus.finished => 'Finalizado',
  AnimeAiringStatus.releasing => 'En emisión',
  AnimeAiringStatus.notYetReleased => 'Próximamente',
  AnimeAiringStatus.cancelled => 'Cancelado',
  AnimeAiringStatus.unknown => 'No disponible',
};

String _seasonName(String value, int? year) =>
    '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}${year == null ? '' : ' $year'}';

String _yearRange(int start, int? end) =>
    end == null || end == start ? '$start' : '$start – $end';
