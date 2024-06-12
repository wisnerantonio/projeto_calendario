import 'package:flutter/material.dart';
import '../models/disciplina.dart';

class DisciplinaProvider with ChangeNotifier {
  final List<Disciplina> _disciplinas = [];
  final Map<DateTime, List<Map<String, dynamic>>> _calendario = {};
  final List<Map<String, dynamic>> _eventosParaImpressao = [];

  List<Disciplina> get disciplinas => _disciplinas;
  Map<DateTime, List<Map<String, dynamic>>> get calendario => _calendario;
  List<Map<String, dynamic>> get eventosParaImpressao => _eventosParaImpressao;

  void adicionarDisciplina(Disciplina disciplina) {
    _disciplinas.add(disciplina);
    notifyListeners();
  }

  void removerEvento(DateTime day, Map<String, dynamic> evento) {
    if (_calendario[day] != null) {
      _calendario[day]!.remove(evento);
      if (_calendario[day]!.isEmpty) {
        _calendario.remove(day);
      }
      _atualizarEventosParaImpressao();
      notifyListeners();
    }
  }

  void adicionarAula(DateTime date, String nomeDisciplina, int qtdeAulas) {
    if (_calendario[date] == null) {
      _calendario[date] = [];
    }
    _calendario[date]!
        .add({'disciplina': nomeDisciplina, 'qtdeAulas': qtdeAulas});
    _atualizarEventosParaImpressao();
    notifyListeners();
  }

  int getCargaHorariaTotal(String nomeDisciplina) {
    int total = 0;
    _calendario.forEach((key, value) {
      for (var item in value) {
        if (item['disciplina'] == nomeDisciplina) {
          total += item['qtdeAulas'] as int;
        }
      }
    });
    return total;
  }

  void adicionarEvento(DateTime day, Map<String, dynamic> evento) {
    if (_calendario[day] == null) {
      _calendario[day] = [];
    }
    _calendario[day]!.add(evento);
    _atualizarEventosParaImpressao();
    notifyListeners();
  }

  void _atualizarEventosParaImpressao() {
    _eventosParaImpressao.clear();
    _calendario.forEach((date, events) {
      _eventosParaImpressao.addAll(events.map((event) {
        return {
          'dia': date,
          'disciplina': event['disciplina'],
          'qtdeAulas': event['qtdeAulas']
        };
      }).toList());
    });
  }

  Map<String, List<String>> getEventsByMonth() {
    Map<String, List<String>> eventsByMonth = {};
    _calendario.forEach((date, events) {
      String month = "${date.month.toString().padLeft(2, '0')}/${date.year}";
      if (!eventsByMonth.containsKey(month)) {
        eventsByMonth[month] = [];
      }
      for (var event in events) {
        eventsByMonth[month]!
            .add("${event['disciplina']} (${event['qtdeAulas']} aulas)");
      }
    });
    return eventsByMonth;
  }
}
