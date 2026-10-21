import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../effects/sfx.dart';
import '../../engine/artwork_export.dart';
import '../../engine/artwork_storage.dart';
import '../../engine/coloring_document.dart';
import '../theme.dart';
import 'bouncy.dart';
import 'mini_art.dart';
import 'parental_gate.dart';

enum ArtworkAction { open, exported, deleted }

/// Long-press sheet on a gallery item: continue · save to phone · delete.
/// Saving and deleting sit behind the parental gate.
Future<ArtworkAction?> showArtworkActions(
    BuildContext context, String id, DocState state) {
  return showModalBottomSheet<ArtworkAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _Sheet(id: id, state: state),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.id, required this.state});
  final String id;
  final DocState state;
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  bool _busy = false;
  String? _message;

  Future<void> _export() async {
    if (!await showParentalGate(context)) return;
    setState(() => _busy = true);
    final d = await Catalog.instance.svgFor(widget.id);
    final ok = await exportToDeviceGallery(d, widget.state,
        paper: Catalog.isFreeId(widget.id) ? Colors.white : CL.paper);
    if (!mounted) return;
    final s = S.of(context);
    SoundFx.instance.play(ok ? Sfx.sparkle : Sfx.wrong);
    setState(() {
      _busy = false;
      _message = ok ? s.savedToPhone : s.saveFailed;
    });
  }

  Future<void> _delete() async {
    if (!await showParentalGate(context)) return;
    await ArtworkStorage.delete(widget.id);
    if (mounted) Navigator.pop(context, ArtworkAction.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 14),
          SizedBox(
            width: 180, height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: MiniArt(drawingId: widget.id, state: widget.state,
                  paper: Catalog.isFreeId(widget.id) ? Colors.white : null),
            ),
          ),
          const SizedBox(height: 16),
          PillButton(label: s.continueDrawing, emoji: '🖌️', width: 300, height: 64, fontSize: 22,
              onTap: () => Navigator.pop(context, ArtworkAction.open)),
          const SizedBox(height: 12),
          PillButton(label: s.saveToPhone, emoji: '📥', width: 300, height: 64, fontSize: 22,
              color: const Color(0xFF3EC1D3), onTap: _busy ? null : _export),
          const SizedBox(height: 12),
          PillButton(label: s.delete, emoji: '🗑️', width: 300, height: 64, fontSize: 22,
              color: const Color(0xFFE57373), onTap: _busy ? null : _delete),
          if (_busy) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: CL.primary)),
          if (_message != null) Padding(padding: const EdgeInsets.all(12), child: Text(_message!, style: CL.text(20))),
        ]),
      ),
    );
  }
}
