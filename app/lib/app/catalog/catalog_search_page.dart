import 'package:anime_app/application/catalog/catalog_service.dart';
import 'package:anime_app/core/result/result.dart';
import 'package:anime_app/domain/catalog/provider_anime_metadata.dart';
import 'package:material_ui/material_ui.dart';

final class CatalogSearchPage extends StatefulWidget {
  const CatalogSearchPage({
    required this.service,
    required this.onOpenDetails,
    super.key,
  });

  final CatalogService service;
  final ValueChanged<ProviderAnimeMetadata> onOpenDetails;

  @override
  State<CatalogSearchPage> createState() => _CatalogSearchPageState();
}

final class _CatalogSearchPageState extends State<CatalogSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  List<ProviderAnimeMetadata> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Result<List<ProviderAnimeMetadata>> result = await widget.service
        .search(query);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success<List<ProviderAnimeMetadata>>(:final value):
          _results = value;
        case Failure<List<ProviderAnimeMetadata>>(:final error):
          _error = error.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                key: const ValueKey('catalog-search-field'),
                controller: _queryController,
                decoration: InputDecoration(
                  labelText: 'Buscar anime',
                  hintText: 'Título o sinopsis',
                  suffixIcon: IconButton(
                    key: const ValueKey('catalog-search-button'),
                    tooltip: 'Buscar',
                    onPressed: () => _search(_queryController.text),
                    icon: const Icon(Icons.search),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _search,
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Catálogo público de AniList · sin iniciar sesión.',
                ),
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: _results.isEmpty && !_loading
                    ? const Center(child: Text('No se encontraron resultados.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ProviderAnimeMetadata item = _results[index];
                          return Card(
                            child: ListTile(
                              key: ValueKey(
                                'catalog-item-${item.externalId.value}',
                              ),
                              leading: const Icon(Icons.movie_outlined),
                              title: Text(item.preferredTitle),
                              subtitle: Text(
                                '${item.releaseYear ?? 'Año desconocido'} · ${item.episodeCount ?? '—'} episodios',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => widget.onOpenDetails(item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
