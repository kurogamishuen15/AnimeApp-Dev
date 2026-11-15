import 'package:material_ui/material_ui.dart';

enum AnimeDetailTab {
  episodes('Episodios'),
  information('Información'),
  cast('Reparto'),
  gallery('Galería'),
  titles('Títulos alternativos'),
  links('Enlaces');

  const AnimeDetailTab(this.label);
  final String label;
}

final class AnimeDetailTabs extends StatelessWidget {
  const AnimeDetailTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AnimeDetailTab selected;
  final ValueChanged<AnimeDetailTab> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xff242329))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AnimeDetailTab.values
              .map((AnimeDetailTab tab) {
                final bool active = selected == tab;
                return Semantics(
                  selected: active,
                  button: true,
                  child: InkWell(
                    key: ValueKey('detail-tab-${tab.name}'),
                    onTap: () => onSelected(tab),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 108),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: active
                                ? const Color(0xffbd38ff)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        tab.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: active
                              ? Colors.white
                              : const Color(0xffc8c4ce),
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    ),
  );
}
