import 'package:material_ui/material_ui.dart';

import '../../application/player/external_subtitles/external_subtitle_service.dart';
import '../../domain/player/subtitles/external_subtitle_catalog.dart';
import '../../domain/player/subtitles/hardsub_policy.dart';

/// Small spike-only search/selection flow. Remote JSON and temporary URLs
/// never enter the widget; it only sees normalized domain values.
final class ExternalSubtitleSearchPanel extends StatefulWidget {
  const ExternalSubtitleSearchPanel({
    required this.service,
    this.hardsubStatus = HardsubStatus.unknown,
    super.key,
  });

  final ExternalSubtitleService service;
  final HardsubStatus hardsubStatus;

  @override
  State<ExternalSubtitleSearchPanel> createState() =>
      _ExternalSubtitleSearchPanelState();
}

final class _ExternalSubtitleSearchPanelState
    extends State<ExternalSubtitleSearchPanel> {
  final TextEditingController _query = TextEditingController();
  List<ExternalSubtitleCandidate> _candidates = const [];
  String? _status;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    final String query = _query.text.trim();
    if (query.isEmpty) {
      setState(() => _status = 'Enter an anime or episode title.');
      return;
    }
    if (query.length > 200) {
      setState(() => _status = 'Search text is limited to 200 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _candidates = const [];
    });
    final result = await widget.service.search(
      ExternalSubtitleQuery(query: query, languages: const ['en']),
    );
    if (!mounted) return;
    switch (result) {
      case ExternalSubtitleSuccess<List<ExternalSubtitleCandidate>>(
        :final value,
      ):
        setState(() {
          _busy = false;
          _candidates = value;
          if (value.isEmpty) _status = 'No subtitles found.';
        });
      case ExternalSubtitleFailure<List<ExternalSubtitleCandidate>>(
        :final kind,
      ):
        setState(() {
          _busy = false;
          _status = _messageFor(kind);
        });
    }
  }

  Future<void> _download(ExternalSubtitleCandidate candidate) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await widget.service.downloadAndLoad(
      candidate,
      hardsubStatus: widget.hardsubStatus,
    );
    if (!mounted) return;
    switch (result) {
      case ExternalSubtitleSuccess<ExternalSubtitleLoadResult>(:final value):
        setState(() {
          _busy = false;
          _status =
              value.hardsubDecision ==
                  ExternalSubtitleDecision.allowedWithUncertainty
              ? 'Subtitle loaded; hardsub status is unknown.'
              : 'Subtitle loaded.';
        });
      case ExternalSubtitleFailure<ExternalSubtitleLoadResult>(:final kind):
        setState(() {
          _busy = false;
          _status = _messageFor(kind);
        });
    }
  }

  String _messageFor(ExternalSubtitleFailureKind kind) => switch (kind) {
    ExternalSubtitleFailureKind.missingApiKey =>
      'OpenSubtitles API key is not configured.',
    ExternalSubtitleFailureKind.blockedByHardsub =>
      'External subtitles are blocked because hardsub is present.',
    ExternalSubtitleFailureKind.rateLimited =>
      'OpenSubtitles rate limit reached. Try again later.',
    ExternalSubtitleFailureKind.quotaExhausted =>
      'OpenSubtitles download quota is exhausted.',
    ExternalSubtitleFailureKind.unauthorized ||
    ExternalSubtitleFailureKind.forbidden =>
      'OpenSubtitles authentication failed.',
    _ => 'Subtitle search or download failed (${kind.name}).',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey<String>('external-subtitle-query'),
              controller: _query,
              decoration: const InputDecoration(
                labelText: 'Search external subtitles (English)',
              ),
              enabled: !_busy,
              maxLength: 200,
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const ValueKey<String>('external-subtitle-search'),
            onPressed: _busy ? null : _search,
            child: Text(_busy ? 'Working…' : 'Search'),
          ),
        ],
      ),
      if (_status case final String value)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            key: const ValueKey<String>('external-subtitle-status'),
          ),
        ),
      for (final ExternalSubtitleCandidate candidate in _candidates)
        ListTile(
          dense: true,
          title: Text(
            '${candidate.language.toUpperCase()} · ${candidate.format.toUpperCase()}${candidate.partCount == null ? '' : ' · Part ${candidate.partNumber ?? 1}/${candidate.partCount}'}',
          ),
          subtitle: Text(candidate.release ?? candidate.fileName),
          trailing: TextButton(
            key: ValueKey<String>(
              'external-subtitle-download-${candidate.fileId}',
            ),
            onPressed: _busy ? null : () => _download(candidate),
            child: const Text('Download & load'),
          ),
        ),
    ],
  );
}
