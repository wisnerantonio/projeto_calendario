import 'package:flutter/material.dart';
import 'package:calendario_disciplinas/models/disciplina.dart';

class EventMarker extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, Disciplina> disciplinas;

  const EventMarker({
    required this.events,
    required this.disciplinas,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const int maxMarkers = 4;
    List<Widget> markers = events.take(maxMarkers).map((event) {
      final disciplina = disciplinas[event['disciplina']];
      return disciplina != null
          ? Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(1.0),
              decoration: BoxDecoration(
                color: disciplina.cor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${event['qtdeAulas']}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            )
          : const SizedBox.shrink(); // Evita erro se disciplina for nula
    }).toList();

    return Stack(
      children: [
        if (markers.isNotEmpty)
          Align(alignment: Alignment.topLeft, child: markers[0]),
        if (markers.length > 1)
          Align(alignment: Alignment.topRight, child: markers[1]),
        if (markers.length > 2)
          Align(alignment: Alignment.bottomRight, child: markers[2]),
        if (markers.length > 3)
          Align(alignment: Alignment.bottomLeft, child: markers[3]),
      ],
    );
  }
}
