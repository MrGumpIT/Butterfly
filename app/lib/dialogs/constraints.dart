import 'package:butterfly/models/element.dart';
import 'package:butterfly/widgets/context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConstraintsContextMenu extends StatefulWidget {
  final ElementConstraints? initialConstraints;
  final bool enableScaled;
  final VoidCallback close;
  final Offset position;
  final ValueChanged<ElementConstraints?> onChanged;
  const ConstraintsContextMenu(
      {Key? key,
      this.enableScaled = true,
      this.initialConstraints,
      required this.close,
      required this.onChanged,
      required this.position})
      : super(key: key);

  @override
  State<ConstraintsContextMenu> createState() => _ConstraintsContextMenuState();
}

class _ConstraintsContextMenuState extends State<ConstraintsContextMenu> {
  late ElementConstraints? constraints;

  @override
  void initState() {
    super.initState();
    constraints = widget.initialConstraints;
  }

  void _onChanged(ElementConstraints? constraints) {
    setState(() {
      this.constraints = constraints;
    });
    widget.onChanged(constraints);
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    String currentType = AppLocalizations.of(context)!.none;
    if (constraints is FixedElementConstraints) {
      content = _FixedConstraintsContent(
          constraints: constraints as FixedElementConstraints,
          onChanged: _onChanged);
      currentType = AppLocalizations.of(context)!.fixedConstraints;
    } else if (constraints is ScaledElementConstraints) {
      content = _ScaledConstraintsContent(
          constraints: constraints as ScaledElementConstraints,
          onChanged: _onChanged);
      currentType = AppLocalizations.of(context)!.scaledConstraints;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(
          children: [
            Expanded(
                child: Text(
              currentType,
              style: Theme.of(context).textTheme.headline6,
            )),
            IconButton(
                icon: const Icon(PhosphorIcons.gearLight),
                onPressed: () {
                  widget.close();

                  showDialog(
                    context: context,
                    builder: (context) {
                      void openNewConstraint(ElementConstraints? constraints) {
                        Navigator.pop(context);
                        widget.onChanged(constraints);
                        showContextMenu(
                          context: context,
                          position: widget.position,
                          builder: (context, close) => ConstraintsContextMenu(
                            close: close,
                            onChanged: widget.onChanged,
                            enableScaled: widget.enableScaled,
                            initialConstraints: constraints,
                            position: widget.position,
                          ),
                        );
                      }

                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.constraints),
                        content: Column(children: [
                          ListTile(
                            title: Text(
                                AppLocalizations.of(context)!.fixedConstraints),
                            onTap: () => openNewConstraint(
                                const FixedElementConstraints(0, 0)),
                          ),
                          if (widget.enableScaled)
                            ListTile(
                              title: Text(AppLocalizations.of(context)!
                                  .scaledConstraints),
                              onTap: () => openNewConstraint(
                                  const ScaledElementConstraints(1)),
                            ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!
                                .dynamicConstraints),
                            onTap: () => openNewConstraint(
                                const DynamicElementConstraints()),
                          ),
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.none),
                            onTap: () => openNewConstraint(null),
                          ),
                        ]),
                        scrollable: true,
                      );
                    },
                  );
                }),
          ],
        ),
        if (content != null) ...[
          const Divider(),
          Flexible(child: content),
        ]
      ]),
    );
  }
}

class _FixedConstraintsContent extends StatelessWidget {
  final FixedElementConstraints constraints;
  final ValueChanged<ElementConstraints?> onChanged;
  const _FixedConstraintsContent(
      {Key? key, required this.constraints, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: [
      TextFormField(
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context)!.width),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) {
            onChanged(constraints.copyWith(width: double.parse(value)));
          },
          initialValue: constraints.width.toStringAsFixed(2)),
      TextFormField(
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context)!.height),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) {
            onChanged(constraints.copyWith(height: double.parse(value)));
          },
          initialValue: constraints.height.toStringAsFixed(2)),
    ]);
  }
}

class _ScaledConstraintsContent extends StatelessWidget {
  final ScaledElementConstraints constraints;
  final ValueChanged<ElementConstraints?> onChanged;
  const _ScaledConstraintsContent(
      {Key? key, required this.constraints, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: [
      TextFormField(
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context)!.scale),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) {
            onChanged(ScaledElementConstraints(double.parse(value)));
          },
          initialValue: constraints.scale.toStringAsFixed(2)),
    ]);
  }
}
