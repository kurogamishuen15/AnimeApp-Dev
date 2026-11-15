import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:material_ui/material_ui.dart';

import 'confirm_completed_status.dart';
import 'detail/anime_detail_header.dart';
import 'detail/anime_detail_tab_content.dart';
import 'detail/anime_detail_tabs.dart';

final class AnimeDetailPage extends StatefulWidget {
  const AnimeDetailPage({
    required this.service,
    required this.fallbackTitle,
    required this.onBack,
    this.onPlaybackRequested,
    this.externalId,
    this.existingAnimeId,
    this.initialMetadata,
    super.key,
  });

  final CatalogService service;
  final String fallbackTitle;
  final VoidCallback onBack;
  final Future<void> Function(PlaybackEpisode episode)? onPlaybackRequested;
  final ExternalAnimeId? externalId;
  final AnimeId? existingAnimeId;
  final ProviderAnimeMetadata? initialMetadata;

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

final class _AnimeDetailPageState extends State<AnimeDetailPage> {
  final TextEditingController _positionController = TextEditingController(
    text: '0',
  );
  ProviderAnimeMetadata? _metadata;
  LibraryEntry? _libraryEntry;
  PlaybackProgress? _progress;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _metadataError;
  bool _loadingLibrary = true;
  AnimeDetailTab _selectedTab = AnimeDetailTab.episodes;

  AnimeId? get _animeId => _libraryEntry?.animeId ?? widget.existingAnimeId;

  @override
  void initState() {
    super.initState();
    _metadata = widget.initialMetadata;
    _loading = widget.initialMetadata == null;
    _load();
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_loadMetadata(), _loadLibrary()]);
  }

  Future<void> _loadMetadata() async {
    final id = widget.externalId;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final cached = await widget.service.readCachedDetails(id);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _metadata = cached;
        _loading = false;
      });
    }
    final details = await widget.service.details(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (details) {
        case Success(:final value):
          _metadata = value;
          _metadataError = null;
        case Failure(:final error):
          _metadataError = error.message;
      }
    });
  }

  Future<void> _retryMetadata() async {
    setState(() {
      _loading = true;
      _metadataError = null;
    });
    await _loadMetadata();
  }

  Future<void> _loadLibrary() async {
    final Result<LibraryEntry?> libraryResult = widget.existingAnimeId != null
        ? await widget.service.getLibraryEntryByAnimeId(widget.existingAnimeId!)
        : widget.externalId == null
        ? const Success(null)
        : await widget.service.getLibraryEntry(widget.externalId!);
    if (!mounted) return;
    if (libraryResult case Success<LibraryEntry?>(:final value)) {
      _libraryEntry = value;
    } else if (libraryResult case Failure<LibraryEntry?>(:final error)) {
      _error ??= error.message;
    }

    final AnimeId? animeId = _animeId;
    if (animeId != null) {
      final Result<PlaybackProgress?> progressResult = await widget.service
          .getProgress(animeId);
      if (!mounted) return;
      if (progressResult case Success<PlaybackProgress?>(:final value)) {
        _progress = value;
        if (value != null) {
          _positionController.text = (value.positionMs ~/ 1000).toString();
        }
      } else if (progressResult case Failure<PlaybackProgress?>(:final error)) {
        _error ??= error.message;
      }
    }
    setState(() => _loadingLibrary = false);
  }

  Future<void> _addToLibrary() async {
    final ProviderAnimeMetadata? metadata = _metadata;
    if (metadata == null || _loadingLibrary || _saving) return;
    setState(() => _saving = true);
    final Result<LibraryEntry> result = await widget.service.addToLibrary(
      metadata,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      switch (result) {
        case Success<LibraryEntry>(:final value):
          _libraryEntry = value;
          _error = null;
        case Failure<LibraryEntry>(:final error):
          _error = error.message;
      }
    });
    if (result case Success<LibraryEntry>()) await _loadProgress();
  }

  Future<void> _setStatus(LibraryStatus status) async {
    if (status == LibraryStatus.completed &&
        !await confirmCompletedStatus(context)) {
      return;
    }
    final AnimeId? animeId = _animeId;
    if (animeId == null) return;
    final Result<LibraryEntry> result = await widget.service.setStatus(
      animeId,
      status,
    );
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Success<LibraryEntry>(:final value):
          _libraryEntry = value;
          _error = null;
        case Failure<LibraryEntry>(:final error):
          _error = error.message;
      }
    });
  }

  Future<void> _loadProgress() async {
    final AnimeId? animeId = _animeId;
    if (animeId == null) return;
    final Result<PlaybackProgress?> result = await widget.service.getProgress(
      animeId,
    );
    if (!mounted) return;
    if (result case Success<PlaybackProgress?>(:final value)) {
      setState(() {
        _progress = value;
        _positionController.text = value == null
            ? '0'
            : (value.positionMs ~/ 1000).toString();
      });
    }
  }

  Future<void> _saveProgress() async {
    final AnimeId? animeId = _animeId;
    if (animeId == null) return;
    final int? seconds = int.tryParse(_positionController.text.trim());
    if (seconds == null || seconds < 0) {
      setState(
        () => _error = 'Introduce una cantidad de segundos no negativa.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final Result<PlaybackProgress> result = await widget.service.saveProgress(
      animeId: animeId,
      positionMs: seconds * 1000,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      switch (result) {
        case Success<PlaybackProgress>(:final value):
          _progress = value;
        case Failure<PlaybackProgress>(:final error):
          _error = error.message;
      }
    });
  }

  Future<void> _playEpisode(int number) async {
    final ProviderAnimeMetadata? metadata = _metadata;
    final Future<void> Function(PlaybackEpisode)? requestPlayback =
        widget.onPlaybackRequested;
    if (metadata == null || requestPlayback == null) return;
    final ExternalAnimeId externalId = metadata.externalId;
    final int? anilistId = externalId.providerId.value == 'anilist'
        ? int.tryParse(externalId.value)
        : null;
    if (anilistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La ficha no tiene un identificador AniList verificable.',
          ),
        ),
      );
      return;
    }
    final AnimeId requestId =
        _animeId ?? AnimeId('playback.anilist.$anilistId');
    final PlaybackEpisode episode = PlaybackEpisode(
      animeId: requestId,
      episodeNumber: number,
      externalAnimeId: externalId,
      animeTitles: {
        metadata.preferredTitle,
        if (metadata.romajiTitle case final String title) title,
        ...metadata.alternativeTitles,
        widget.fallbackTitle,
      },
    );
    try {
      await requestPlayback(episode);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la búsqueda del episodio.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProviderAnimeMetadata? metadata = _metadata;
    final LibraryEntry? entry = _libraryEntry;
    final String title = metadata?.preferredTitle ?? widget.fallbackTitle;
    return Scaffold(
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          AnimeDetailHeader(
            title: title,
            metadata: metadata,
            entry: entry,
            saving: _saving || _loadingLibrary,
            onBack: widget.onBack,
            onAdd: _addToLibrary,
            onStatus: _setStatus,
          ),
          if (_metadataError != null || _error != null)
            Container(
              width: double.infinity,
              color: const Color(0xff120c16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _metadataError != null && metadata == null
                          ? 'No se pudieron cargar los metadatos. $_metadataError'
                          : (_error ?? _metadataError!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xffffb8bd),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_metadataError != null && !_loading)
                    TextButton(
                      onPressed: _retryMetadata,
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          AnimeDetailTabs(
            selected: _selectedTab,
            onSelected: (AnimeDetailTab tab) =>
                setState(() => _selectedTab = tab),
          ),
          Expanded(
            child: AnimeDetailTabContent(
              tab: _selectedTab,
              metadata: metadata,
              progress: _progress,
              canSaveProgress: _animeId != null,
              positionController: _positionController,
              saving: _saving,
              error: _error,
              onSaveProgress: _saveProgress,
              onPlayEpisode: widget.onPlaybackRequested == null
                  ? null
                  : _playEpisode,
            ),
          ),
        ],
      ),
    );
  }
}
