import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/library_entry.dart';
import 'package:material_ui/material_ui.dart';

import 'confirm_completed_status.dart';

final class LocalLibraryPage extends StatefulWidget {
  const LocalLibraryPage({
    required this.service,
    required this.onOpenDetails,
    this.refreshRevision = 0,
    super.key,
  });

  final CatalogService service;
  final ValueChanged<CatalogLibraryItem> onOpenDetails;
  final int refreshRevision;

  @override
  State<LocalLibraryPage> createState() => _LocalLibraryPageState();
}

final class _LocalLibraryPageState extends State<LocalLibraryPage> {
  List<CatalogLibraryItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant LocalLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshRevision != oldWidget.refreshRevision) _reload();
  }

  int _loadGeneration = 0;

  Future<void> _reload() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    final Result<List<CatalogLibraryItem>> result = await widget.service
        .loadLibrary();
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success<List<CatalogLibraryItem>>(:final value):
          _items = value;
        case Failure<List<CatalogLibraryItem>>(:final error):
          _error = error.message;
      }
    });
  }

  Future<void> _changeStatus(
    CatalogLibraryItem item,
    LibraryStatus status,
  ) async {
    if (status == LibraryStatus.completed &&
        !await confirmCompletedStatus(context)) {
      return;
    }
    final Result<LibraryEntry> result = await widget.service.setStatus(
      item.entry.animeId,
      status,
    );
    if (!mounted) return;
    if (result case Failure<LibraryEntry>(:final error)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Tu biblioteca está vacía. Añade una serie del catálogo.'),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (BuildContext context, int index) {
              final CatalogLibraryItem item = _items[index];
              return Card(
                child: ListTile(
                  key: ValueKey('library-item-${item.entry.animeId.value}'),
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text(item.title),
                  subtitle: Text(
                    item.metadata == null
                        ? 'Contenido local · ${_statusLabel(item.entry.status)}'
                        : '${item.metadata!.releaseYear ?? 'Año desconocido'} · ${_statusLabel(item.entry.status)}',
                  ),
                  onTap: () => widget.onOpenDetails(item),
                  trailing: DropdownButton<LibraryStatus>(
                    key: ValueKey('library-status-${item.entry.animeId.value}'),
                    value: item.entry.status,
                    items: LibraryStatus.values
                        .map(
                          (LibraryStatus status) =>
                              DropdownMenuItem<LibraryStatus>(
                                value: status,
                                child: Text(_statusLabel(status)),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (LibraryStatus? status) {
                      if (status != null) _changeStatus(item, status);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _statusLabel(LibraryStatus status) => switch (status) {
  LibraryStatus.planned => 'Por ver',
  LibraryStatus.watching => 'Viendo',
  LibraryStatus.rewatching => 'Reviendo',
  LibraryStatus.paused => 'Pausados',
  LibraryStatus.completed => 'Completados',
  LibraryStatus.abandoned => 'Abandonados',
};
