import 'dart:typed_data';

import 'package:butterfly/views/toolbar.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../bloc/document_bloc.dart';
import '../../helpers/element_helper.dart';

class ComponentsToolbarView extends StatefulWidget
    implements PreferredSizeWidget {
  final PackAssetLocation component;
  final ValueChanged<PackAssetLocation> onChanged;

  const ComponentsToolbarView({
    super.key,
    required this.component,
    required this.onChanged,
  });

  @override
  State<ComponentsToolbarView> createState() => _ComponentsToolbarViewState();

  @override
  Size get preferredSize => kToolbarLarge;
}

class _ComponentsToolbarViewState extends State<ComponentsToolbarView> {
  final ScrollController _scrollController = ScrollController();
  late String currentPack;

  @override
  void initState() {
    super.initState();
    currentPack = widget.component.pack;
    final state = context.read<DocumentBloc>().state;
    if (state is! DocumentLoaded) return;
    final pack = state.data.getPack(widget.component.pack);
    if (pack != null) return;
    currentPack = state.data.getPacks().firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<DocumentBloc>().state;
    if (state is! DocumentLoadSuccess) return const SizedBox.shrink();
    return StreamBuilder<NoteData>(
        stream: state.data.onChange,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final bloc = context.read<DocumentBloc>();
          final document = snapshot.data!;

          final component = widget.component.resolveComponent(document);
          final pack = document.getPack(currentPack);
          final components = pack
                  ?.getComponents()
                  .map((e) {
                    final component = pack.getComponent(e);
                    if (component == null) return null;
                    return (e, component);
                  })
                  .whereNotNull()
                  .toList() ??
              [];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentPack != widget.component.pack &&
                  component != null) ...[
                _ComponentsButton(
                  component: widget.component,
                  value: component,
                  bloc: bloc,
                  pack: pack,
                  onChanged: () {},
                ),
                const VerticalDivider(),
              ],
              Expanded(
                  child: Scrollbar(
                controller: _scrollController,
                child: ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...List.generate(components.length, (index) {
                        final current = components[index];
                        return _ComponentsButton(
                          bloc: bloc,
                          component: widget.component,
                          value: current.$2,
                          pack: pack,
                          onChanged: () {
                            widget.onChanged(PackAssetLocation(
                              currentPack,
                              current.$1,
                            ));
                          },
                        );
                      }),
                    ]),
              )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MenuAnchor(
                  builder: defaultMenuButton(),
                  menuChildren: document
                      .getPacks()
                      .map((e) => RadioMenuButton(
                          value: e,
                          groupValue: currentPack,
                          onChanged: (value) =>
                              setState(() => currentPack = value ?? e),
                          child: Text(e)))
                      .toList(),
                ),
              ),
            ],
          );
        });
  }
}

class _ComponentsButton extends StatelessWidget {
  final ButterflyComponent value;
  final PackAssetLocation? component;
  final NoteData? pack;
  final DocumentBloc bloc;
  final VoidCallback onChanged;

  const _ComponentsButton({
    required this.component,
    required this.value,
    required this.bloc,
    required this.onChanged,
    required this.pack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
          onTap: onChanged,
          borderRadius: BorderRadius.circular(12),
          child: FutureBuilder<Uint8List?>(
            future: value.thumbnail == null || pack == null
                ? null
                : getDataFromSource(pack!, value.thumbnail!),
            builder: (context, snapshot) {
              const fallbackWidget = AspectRatio(
                aspectRatio: 1,
                child: PhosphorIcon(PhosphorIconsLight.selection),
              );
              if (!snapshot.hasData) return fallbackWidget;
              return Image.memory(
                snapshot.data!,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => fallbackWidget,
              );
            },
          )),
    );
  }
}
