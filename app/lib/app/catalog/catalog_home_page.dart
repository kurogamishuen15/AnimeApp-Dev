import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/application/player/playback_progress_session.dart';
import 'package:anime_app/application/player/providers/playback_provider_manager.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/anime_id.dart';
import 'package:anime_app/domain/catalog/anime_identity.dart';
import 'package:anime_app/domain/catalog/external_anime_id.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:anime_app/domain/player/providers/playback_provider_contract.dart';
import 'package:anime_app/domain/player/providers/playback_source.dart';
import 'package:anime_app/domain/progress/checkpoint_coordinator.dart';
import 'package:anime_app/domain/progress/playback_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../home/home_appearance.dart';
import '../home/home_card_actions.dart';
import '../home/home_data.dart';
import '../home/home_icons.dart';
import '../home/home_screen.dart';
import '../player/provider_playback_route.dart';
import 'anime_detail_page.dart';
import 'catalog_search_page.dart';
import 'confirm_completed_status.dart';
import 'local_library_page.dart';
import 'playback_resolution_message.dart';

final class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({
    required this.service,
    this.playbackProviders,
    super.key,
  });

  final CatalogService service;
  final PlaybackProviderManager? playbackProviders;

  @override
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}

final class _CatalogHomePageState extends State<CatalogHomePage>
    with RestorationMixin {
  final RestorableInt _selectedIndex = RestorableInt(0);

  @override
  String get restorationId => 'catalog-shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedIndex, 'destination');
  }

  @override
  void dispose() {
    _cancelPlaybackResolution();
    _selectedIndex.dispose();
    super.dispose();
  }

  int _homeRevision = 0;
  int _libraryRevision = 0;
  final List<_DetailRequest> _detailStack = [];
  PlaybackCancellationToken? _playbackCancellation;
  bool _resolvingPlayback = false;

  void _cancelPlaybackResolution() {
    _playbackCancellation?.cancel();
    _playbackCancellation = null;
    _resolvingPlayback = false;
  }

  void _select(int index) {
    if (index == _selectedIndex.value && _detailStack.isEmpty) return;
    _cancelPlaybackResolution();
    setState(() {
      _detailStack.clear();
      _selectedIndex.value = index;
      if (index == 0) _homeRevision++;
      if (index == 2) _libraryRevision++;
    });
  }

  void _openDetails(HomeTitle anime) => _pushDetails(
    _DetailRequest(
      externalId: anime.externalId,
      existingAnimeId: anime.animeId,
      fallbackTitle: anime.title,
      initialMetadata: anime.metadata,
    ),
  );

  void _openSearchDetails(ProviderAnimeMetadata metadata) => _pushDetails(
    _DetailRequest(
      externalId: metadata.externalId,
      fallbackTitle: metadata.preferredTitle,
      initialMetadata: metadata,
    ),
  );

  void _openLibraryDetails(CatalogLibraryItem item) => _pushDetails(
    _DetailRequest(
      externalId: item.externalId ?? item.metadata?.externalId,
      existingAnimeId: item.entry.animeId,
      fallbackTitle: item.title,
      initialMetadata: item.metadata,
    ),
  );

  void _pushDetails(_DetailRequest request) {
    _cancelPlaybackResolution();
    setState(() => _detailStack.add(request));
  }

  void _closeDetails() {
    if (_detailStack.isEmpty) return;
    _cancelPlaybackResolution();
    setState(() {
      _detailStack.removeLast();
      _homeRevision++;
      _libraryRevision++;
    });
  }

  Future<void> _resumeEpisode(HomeEpisode episode) async {
    final PlaybackEpisode? playback = episode.playback;
    if (playback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este progreso no tiene un episodio reproducible.'),
        ),
      );
      return;
    }
    await _playEpisode(
      playback,
      startPosition: Duration(milliseconds: episode.positionMs),
    );
  }

  Future<void> _playEpisode(
    PlaybackEpisode episode, {
    Duration? startPosition,
  }) async {
    final PlaybackProviderManager? manager = widget.playbackProviders;
    if (manager == null || _resolvingPlayback) return;
    final PlaybackCancellationToken cancellation = PlaybackCancellationToken();
    _playbackCancellation = cancellation;
    _resolvingPlayback = true;
    try {
      final PlaybackProviderResult<List<ResolvedPlaybackStream>> result =
          await manager.resolveCandidates(episode, cancellation: cancellation);
      if (!mounted || cancellation.isCancelled) return;
      final List<ResolvedPlaybackStream> streams = switch (result) {
        PlaybackProviderSuccess<List<ResolvedPlaybackStream>>(:final value) =>
          value,
        PlaybackProviderEmpty<List<ResolvedPlaybackStream>>() => const [],
        PlaybackProviderFailed<List<ResolvedPlaybackStream>>() ||
        PlaybackProviderUnsupported<List<ResolvedPlaybackStream>>() => const [],
      };
      if (streams.isEmpty) {
        final String message =
            playbackResolutionMessage(result) ??
            'No se encontraron fuentes para este episodio.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      final ResolvedPlaybackStream? selected =
          await showModalBottomSheet<ResolvedPlaybackStream>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) =>
                _PlaybackSourcePicker(streams: streams),
          );
      if (!mounted || cancellation.isCancelled || selected == null) return;
      final identity = await widget.service.identities.getById(episode.animeId);
      final bool hasLocalIdentity =
          identity is Success<AnimeIdentity?> && identity.value != null;
      Duration? resume = startPosition;
      if (resume == null && hasLocalIdentity) {
        final saved = await widget.service.getEpisodeProgress(
          episode.animeId,
          episode.episodeNumber,
        );
        if (saved
            case Success<PlaybackProgress?>(
              value: final PlaybackProgress progress,
            )
            when progress.completion == CompletionState.inProgress) {
          resume = Duration(milliseconds: progress.resumePositionMs);
        }
      }
      if (!mounted || cancellation.isCancelled) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ProviderPlaybackRoute(
            manager: manager,
            episode: episode,
            streams: streams,
            initialStream: selected,
            startPosition: resume ?? Duration.zero,
            trackProgress: hasLocalIdentity
                ? (player) => PlaybackProgressSession(
                    player,
                    CheckpointCoordinator(
                      write: widget.service.progress.upsert,
                    ),
                    CatalogService.episodeProgressKey(
                      episode.animeId,
                      episode.episodeNumber,
                    ),
                  )
                : null,
          ),
        ),
      );
      if (mounted && !cancellation.isCancelled) {
        setState(() => _homeRevision++);
      }
    } finally {
      if (identical(_playbackCancellation, cancellation)) {
        _playbackCancellation = null;
        _resolvingPlayback = false;
      }
    }
  }

  Future<void> _applyCardLibraryAction(
    HomeTitle title,
    HomeCardLibraryCommand command,
  ) async {
    if (command.details) {
      _openDetails(title);
      return;
    }
    if (command.copyLink) {
      final uri = HomeCardActionPolicy.linkFor(title);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No link is available for this title.')),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Link copied.')));
      }
      return;
    }
    if (command.remove) {
      final animeId = title.animeId;
      if (animeId == null) return;
      final result = await widget.service.removeFromLibrary(animeId);
      if (!mounted) return;
      if (result case Failure<void>(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      } else {
        setState(() {
          _homeRevision++;
          _libraryRevision++;
        });
      }
      return;
    }
    if (!command.add && command.status == LibraryStatus.completed) {
      if (!await confirmCompletedStatus(context)) return;
      if (!mounted) return;
    }
    Result<LibraryEntry>? result;
    if (command.add) {
      final externalId = title.externalId;
      if (externalId != null) {
        final details = await widget.service.details(externalId);
        if (details case Success<ProviderAnimeMetadata>(:final value)) {
          result = await widget.service.addToLibrary(value);
        } else if (details case Failure<ProviderAnimeMetadata>(:final error)) {
          result = Failure(error);
        }
      }
    } else if (title.animeId case final animeId?) {
      final status = command.status;
      if (status != null) {
        result = await widget.service.setStatus(animeId, status);
      }
    }
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la biblioteca.')),
      );
    } else if (result case Failure(:final error)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } else {
      setState(() {
        _homeRevision++;
        _libraryRevision++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= 760 &&
        MediaQuery.textScalerOf(context).scale(14) <= 18;
    final tvLayout =
        defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.of(context).navigationMode == NavigationMode.directional;
    return PopScope<Object?>(
      canPop: _detailStack.isEmpty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _detailStack.isNotEmpty) _closeDetails();
      },
      child: Scaffold(
        body: Row(
          children: [
            if (wide)
              _DesktopSidebar(
                selectedIndex: _selectedIndex.value,
                onSelect: _select,
              ),
            Expanded(
              child: Column(
                children: [
                  _HomeHeader(
                    wide: wide,
                    tvLayout: tvLayout,
                    selectedIndex: _selectedIndex.value,
                    onSelect: _select,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _detailStack.isEmpty
                          ? _selectedIndex.value
                          : 3 + _detailStack.length - 1,
                      children: [
                        HomeScreen(
                          load: CatalogHomeSource(widget.service).load,
                          onDetails: _openDetails,
                          onLibraryAction: _applyCardLibraryAction,
                          onResume: _resumeEpisode,
                          refreshRevision: _homeRevision,
                        ),
                        CatalogSearchPage(
                          service: widget.service,
                          onOpenDetails: _openSearchDetails,
                        ),
                        LocalLibraryPage(
                          service: widget.service,
                          onOpenDetails: _openLibraryDetails,
                          refreshRevision: _libraryRevision,
                        ),
                        for (
                          int index = 0;
                          index < _detailStack.length;
                          index++
                        )
                          AnimeDetailPage(
                            key: ValueKey('anime-detail-$index'),
                            service: widget.service,
                            fallbackTitle: _detailStack[index].fallbackTitle,
                            externalId: _detailStack[index].externalId,
                            existingAnimeId:
                                _detailStack[index].existingAnimeId,
                            initialMetadata:
                                _detailStack[index].initialMetadata,
                            onPlaybackRequested:
                                widget.playbackProviders == null
                                ? null
                                : _playEpisode,
                            onBack: _closeDetails,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide || tvLayout
            ? null
            : NavigationBar(
                backgroundColor: HomeAppearance.of(context).surface,
                selectedIndex: _selectedIndex.value,
                onDestinationSelected: _select,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_outlined),
                    label: 'Inicio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    label: 'Catálogo',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.video_library_outlined),
                    label: 'Mi biblioteca',
                  ),
                ],
              ),
      ),
    );
  }
}

final class _PlaybackSourcePicker extends StatelessWidget {
  const _PlaybackSourcePicker({required this.streams});

  final List<ResolvedPlaybackStream> streams;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuentes encontradas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .55,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: streams.length,
              itemBuilder: (BuildContext context, int index) {
                final ResolvedPlaybackStream stream = streams[index];
                return ListTile(
                  key: ValueKey<String>(
                    'source-${stream.providerId.value}-${stream.serverId}',
                  ),
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(stream.sourceLabel ?? stream.providerId.value),
                  subtitle: Text(stream.displayName ?? stream.serverId),
                  onTap: () => Navigator.of(context).pop(stream),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _DetailRequest {
  const _DetailRequest({
    required this.fallbackTitle,
    this.externalId,
    this.existingAnimeId,
    this.initialMetadata,
  });

  final String fallbackTitle;
  final ExternalAnimeId? externalId;
  final AnimeId? existingAnimeId;
  final ProviderAnimeMetadata? initialMetadata;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: 68,
    decoration: const BoxDecoration(
      color: HomeAppearance.background,
      border: Border(right: BorderSide(color: Color(0xff17171c))),
    ),
    child: Column(
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.blur_circular, color: Color(0xffc793ff), size: 29),
        const SizedBox(height: 28),
        _SidebarButton(
          action: HomeAction.search,
          selected: selectedIndex == 1,
          onTap: () => onSelect(1),
        ),
        _SidebarButton(
          action: HomeAction.home,
          selected: selectedIndex == 0,
          onTap: () => onSelect(0),
        ),
        const _SidebarButton(action: HomeAction.calendar),
        const _SidebarButton(action: HomeAction.discover),
        _SidebarButton(
          action: HomeAction.library,
          selected: selectedIndex == 2,
          onTap: () => onSelect(2),
        ),
        const Spacer(),
        const _SidebarButton(action: HomeAction.settings),
        const SizedBox(height: 12),
        const _SidebarButton(action: HomeAction.profile),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.action,
    this.selected = false,
    this.onTap,
  });
  final HomeAction action;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = HomeIcons.resolve(action);
    final label = switch (action) {
      HomeAction.home => 'Inicio',
      HomeAction.search => 'Buscar',
      HomeAction.calendar => 'Calendario · Próximamente',
      HomeAction.discover => 'Descubrir · Próximamente',
      HomeAction.library => 'Biblioteca',
      HomeAction.settings => 'Configuración',
      HomeAction.profile => 'Perfil sin iniciar sesión',
      HomeAction.details => 'Ver detalles',
      HomeAction.more => 'Más acciones',
      HomeAction.bookmarkAdd => 'Añadir a biblioteca',
      HomeAction.planned => 'Por ver',
      HomeAction.watching => 'Viendo',
      HomeAction.rewatching => 'Reviendo',
      HomeAction.paused => 'Pausados',
      HomeAction.completed => 'Completados',
      HomeAction.abandoned => 'Abandonados',
      HomeAction.selected => 'Seleccionado',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 7),
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
          foregroundColor: selected ? const Color(0xffe0baff) : Colors.white,
          backgroundColor: selected
              ? const Color(0xff493765)
              : Colors.transparent,
          minimumSize: const Size(52, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.wide,
    required this.tvLayout,
    required this.selectedIndex,
    required this.onSelect,
  });
  final bool wide;
  final bool tvLayout;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (wide && !tvLayout) return const SizedBox.shrink();
    return Container(
      height: tvLayout ? 116 : 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: HomeAppearance.background,
        border: Border(bottom: BorderSide(color: Color(0xff17171c))),
      ),
      child: Row(
        children: [
          Text(
            'Kongroo',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -.35),
          ),
          const Spacer(),
          if (wide) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                key: const ValueKey('home-search-field'),
                readOnly: true,
                onTap: () => onSelect(1),
                decoration: InputDecoration(
                  hintText: 'Buscar anime, géneros o temporadas…',
                  prefixIcon: const Icon(Icons.search_outlined),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xff151519),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xff37373e)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xff37373e)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Tooltip(
              message: 'Perfil sin iniciar sesión',
              child: Semantics(
                label: 'Sin iniciar sesión',
                child: Icon(Icons.account_circle_outlined, size: 28),
              ),
            ),
          ] else
            IconButton(
              tooltip: 'Buscar',
              onPressed: () => onSelect(1),
              icon: const Icon(Icons.search_outlined),
            ),
          if (tvLayout) ...[
            const SizedBox(width: 12),
            NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Catálogo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  label: 'Mi biblioteca',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
