import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calendario_disciplinas/models/disciplina.dart';
import 'package:calendario_disciplinas/providers/disciplina_provider.dart';
import 'package:calendario_disciplinas/widgets/event_marker.dart';
import 'package:pdf/widgets.dart' as pdf_lib;

class CalendarDisciplinas extends StatefulWidget {
  const CalendarDisciplinas({super.key});

  @override
  CalendarDisciplinasState createState() => CalendarDisciplinasState();
}

class CalendarDisciplinasState extends State<CalendarDisciplinas> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _selectedCurso;
  String? _selectedDisciplina;
  int _selectedHoras = 1;
  DateTime _focusedDay = DateTime.now();

  final Map<String, List<String>> cursos = {
    'Técnico em Informática': [
      'UC1 - Planejar e executar a montagem de computadores',
      'UC2 - Planejar e executar a instalação de hardware e software para computadores',
      'UC3 - Planejar e executar a manutenção de computadores',
    ],
    'Curso B': ['Disciplina 4', 'Disciplina 5'],
    'Curso C': ['Disciplina 6', 'Disciplina 7', 'Disciplina 8', 'Disciplina 9'],
  };

  final Map<String, Disciplina> disciplinas = {
    'UC1 - Planejar e executar a montagem de computadores': Disciplina(
        'UC1 - Planejar e executar a montagem de computadores', 40, Colors.red),
    'UC2 - Planejar e executar a instalação de hardware e software para computadores':
        Disciplina(
            'UC2 - Planejar e executar a instalação de hardware e software para computadores',
            40,
            Colors.green),
    'UC3 - Planejar e executar a manutenção de computadores': Disciplina(
        'UC3 - Planejar e executar a manutenção de computadores',
        40,
        Colors.blue),
    'Disciplina 4': Disciplina('Disciplina 4', 40, Colors.yellow),
    'Disciplina 5': Disciplina('Disciplina 5', 40, Colors.orange),
    'Disciplina 6': Disciplina('Disciplina 6', 40, Colors.purple),
    'Disciplina 7': Disciplina('Disciplina 7', 40, Colors.brown),
    'Disciplina 8': Disciplina('Disciplina 8', 40, Colors.cyan),
    'Disciplina 9': Disciplina('Disciplina 9', 40, Colors.pink),
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  String _getDisciplinaName(String disciplina) {
    return disciplina.split(' - ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Disciplinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _printCalendar();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.3,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selecione um Curso',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          value: _selectedCurso,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCurso = newValue;
                              _selectedDisciplina = null;
                            });
                          },
                          items: cursos.keys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.3,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selecione uma Disciplina',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          value: _selectedDisciplina,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDisciplina = newValue;
                            });
                          },
                          items: (_selectedCurso != null
                                  ? cursos[_selectedCurso]!
                                  : <String>[])
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(_getDisciplinaName(value)),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_selectedDisciplina != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.2,
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Horas',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _selectedHoras = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<DisciplinaProvider>(
                  builder: (context, provider, child) {
                    final cargaHorariaPorDisciplina =
                        _calcularCargaHorariaPorDisciplina(provider);
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: TableCalendar<Map<String, dynamic>>(
                              locale: 'pt_BR',
                              firstDay: DateTime.utc(2020, 10, 16),
                              lastDay: DateTime.utc(2030, 3, 14),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Mês',
                              },
                              eventLoader: (day) =>
                                  provider.calendario[day] ?? [],
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _focusedDay = focusedDay;
                                });
                                _showAdicionarOuRemoverAulaDialog(
                                    context, selectedDay, provider);
                              },
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle:
                                    const TextStyle().copyWith(fontSize: 12),
                                weekendStyle:
                                    const TextStyle().copyWith(fontSize: 12),
                              ),
                              calendarStyle: CalendarStyle(
                                cellMargin: const EdgeInsets.all(1),
                                defaultTextStyle: const TextStyle(fontSize: 12),
                                rowDecoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey, width: 0.5),
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  return events.isNotEmpty
                                      ? EventMarker(
                                          events: events,
                                          disciplinas: disciplinas,
                                        )
                                      : null;
                                },
                                defaultBuilder: (context, day, focusedDay) {
                                  final events = provider.calendario[day] ?? [];
                                  final isToday = day == DateTime.now();
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: events.isNotEmpty && !isToday
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          color: events.isNotEmpty
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Carga horária mensal total: ${_calcularCargaHorariaMensal(provider)} horas',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: cargaHorariaPorDisciplina.entries
                                  .map((entry) {
                                return Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: entry.value['cor'],
                                      margin: const EdgeInsets.only(right: 8),
                                    ),
                                    Text(
                                      '${entry.key}: ${entry.value['horas']} horas',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdicionarOuRemoverAulaDialog(
      BuildContext context, DateTime selectedDay, DisciplinaProvider provider) {
    final eventos = provider.calendario[selectedDay] ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gerenciar eventos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedCurso != null && _selectedDisciplina != null)
                ElevatedButton.icon(
                  onPressed: () {
                    _showAdicionarAulaDialog(context, selectedDay);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Adicionar Evento',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (eventos.isNotEmpty) ...[
                const Text('Eventos existentes:'),
                const SizedBox(height: 8),
                for (var event in eventos)
                  ListTile(
                    title: Text(
                        '${event['disciplina']} - ${event['qtdeAulas']} aulas'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        provider.removerEvento(selectedDay, event);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
              ] else
                const Text('Nenhum evento neste dia.'),
            ],
          ),
        );
      },
    );
  }

  void _showAdicionarAulaDialog(BuildContext context, DateTime selectedDay) {
    if (_selectedCurso == null || _selectedDisciplina == null) {
      _showErrorDialog(
          context, 'Por favor, selecione um curso e uma disciplina.');
      return;
    }

    final provider = Provider.of<DisciplinaProvider>(context, listen: false);
    final disciplina = disciplinas[_selectedDisciplina!];

    if (disciplina == null) {
      _showErrorDialog(context, 'Disciplina não encontrada.');
      return;
    }

    provider.adicionarEvento(selectedDay, {
      'disciplina': disciplina.nome,
      'qtdeAulas': _selectedHoras,
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int _calcularCargaHorariaMensal(DisciplinaProvider provider) {
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final fimMes = DateTime(now.year, now.month + 1, 0);

    int cargaHoraria = 0;
    provider.calendario.forEach((date, events) {
      if (date.isAfter(inicioMes) && date.isBefore(fimMes)) {
        cargaHoraria += events.fold<int>(
            0, (sum, event) => sum + event['qtdeAulas'] as int);
      }
    });

    return cargaHoraria;
  }

  Map<String, Map<String, dynamic>> _calcularCargaHorariaPorDisciplina(
      DisciplinaProvider provider) {
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final fimMes = DateTime(now.year, now.month + 1, 0);

    Map<String, Map<String, dynamic>> cargaHorariaPorDisciplina = {};

    provider.calendario.forEach((date, events) {
      if (date.isAfter(inicioMes) && date.isBefore(fimMes)) {
        for (var event in events) {
          final disciplina = event['disciplina'];
          final qtdeAulas = event['qtdeAulas'] as int;
          if (cargaHorariaPorDisciplina.containsKey(disciplina)) {
            cargaHorariaPorDisciplina[disciplina]!['horas'] += qtdeAulas;
          } else {
            cargaHorariaPorDisciplina[disciplina] = {
              'horas': qtdeAulas,
              'cor': disciplinas[disciplina]?.cor ?? Colors.grey
            };
          }
        }
      }
    });

    return cargaHorariaPorDisciplina;
  }

  Future<void> _printCalendar() async {
    final pdf_lib.Document pdf = pdf_lib.Document();

    final provider = Provider.of<DisciplinaProvider>(context, listen: false);
    final cargaHorariaPorDisciplina =
        _calcularCargaHorariaPorDisciplina(provider);
    final eventosParaImpressao = provider.eventosParaImpressao;

    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final List<List<pdf_lib.Widget>> calendarRows = [];
    List<pdf_lib.Widget> row = [];

    // List of weekdays
    final List<String> weekdays = [
      'Dom',
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb'
    ];

    // Add weekdays header
    calendarRows.add(
      weekdays
          .map((day) => pdf_lib.Container(
                width: 40,
                height: 40,
                child: pdf_lib.Center(
                  child: pdf_lib.Text(
                    day,
                    style:
                        pdf_lib.TextStyle(fontWeight: pdf_lib.FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );

    // Adjust first day of the month to the correct weekday
    final int firstWeekdayOfMonth =
        DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7;
    row.addAll(List.filled(
        firstWeekdayOfMonth, pdf_lib.Container(width: 40, height: 40)));

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(_focusedDay.year, _focusedDay.month, day);
      final events = eventosParaImpressao
          .where((event) =>
              event['dia'].year == currentDate.year &&
              event['dia'].month == currentDate.month &&
              event['dia'].day == currentDate.day)
          .toList();

      row.add(
        pdf_lib.Container(
          width: 40,
          height: 40,
          decoration: pdf_lib.BoxDecoration(
            border: pdf_lib.Border.all(color: PdfColors.grey, width: 0.5),
          ),
          child: pdf_lib.Stack(
            alignment: pdf_lib.Alignment.center,
            children: [
              pdf_lib.Positioned(
                top: 2,
                child: pdf_lib.Text(
                  '$day',
                  style: const pdf_lib.TextStyle(
                    color: PdfColors.black,
                  ),
                ),
              ),
              if (events.isNotEmpty)
                ...events.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final disciplina = disciplinas[event['disciplina']];

                  // Define position based on index
                  double? top;
                  double? left;
                  double? bottom;
                  double? right;

                  switch (index) {
                    case 0:
                      top = 2;
                      left = 2;
                      break;
                    case 1:
                      top = 2;
                      right = 2;
                      break;
                    case 2:
                      bottom = 2;
                      left = 2;
                      break;
                    case 3:
                      bottom = 2;
                      right = 2;
                      break;
                  }

                  return pdf_lib.Positioned(
                    top: top,
                    left: left,
                    bottom: bottom,
                    right: right,
                    child: pdf_lib.Container(
                      padding: const pdf_lib.EdgeInsets.all(2),
                      decoration: pdf_lib.BoxDecoration(
                        color: PdfColor.fromInt(disciplina!.cor.value),
                        borderRadius: pdf_lib.BorderRadius.circular(4),
                      ),
                      child: pdf_lib.Text(
                        '${event['qtdeAulas']}h',
                        style: const pdf_lib.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                        textAlign: pdf_lib.TextAlign.center,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );

      if (row.length == 7 || day == daysInMonth) {
        calendarRows.add(row);
        row = [];
      }
    }

    pdf.addPage(
      pdf_lib.Page(
        build: (context) => pdf_lib.Column(
          crossAxisAlignment: pdf_lib.CrossAxisAlignment.start,
          children: [
            pdf_lib.Center(
              child: pdf_lib.Text(
                'Curso: $_selectedCurso',
                style: pdf_lib.TextStyle(
                    fontSize: 20, fontWeight: pdf_lib.FontWeight.bold),
              ),
            ),
            pdf_lib.SizedBox(height: 10),
            pdf_lib.Text(
              'Cronograma do Mês de ${DateFormat.MMMM('pt_BR').format(_focusedDay)}',
              style: pdf_lib.TextStyle(
                  fontSize: 14, fontWeight: pdf_lib.FontWeight.bold),
            ),
            pdf_lib.SizedBox(height: 15),
            pdf_lib.Table(
              border:
                  pdf_lib.TableBorder.all(color: PdfColors.grey, width: 0.5),
              children: [
                // Cabeçalho da tabela
                pdf_lib.TableRow(
                  children: [
                    pdf_lib.Container(
                      padding: const pdf_lib.EdgeInsets.all(4),
                      child: pdf_lib.Text(
                        'Unidades Curriculares',
                        textAlign: pdf_lib.TextAlign.left,
                        style: pdf_lib.TextStyle(
                            fontWeight: pdf_lib.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pdf_lib.Container(
                      padding: const pdf_lib.EdgeInsets.all(4),
                      child: pdf_lib.Text(
                        'Horas',
                        textAlign: pdf_lib.TextAlign.center,
                        style: pdf_lib.TextStyle(
                          fontWeight: pdf_lib.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pdf_lib.Container(
                      padding: const pdf_lib.EdgeInsets.all(4),
                      child: pdf_lib.Text(
                        'Cores',
                        textAlign: pdf_lib.TextAlign.center,
                        style: pdf_lib.TextStyle(
                          fontWeight: pdf_lib.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                // Linhas da tabela
                ...cargaHorariaPorDisciplina.entries.map((entry) {
                  final disciplina = entry.key;
                  final horas = entry.value['horas'].toString();
                  final cor = disciplinas[disciplina]!.cor;
                  return pdf_lib.TableRow(
                    children: [
                      pdf_lib.Container(
                        padding: const pdf_lib.EdgeInsets.all(4),
                        child: pdf_lib.Text(disciplina,
                            textAlign: pdf_lib.TextAlign.left,
                            style: const pdf_lib.TextStyle(fontSize: 10)),
                      ),
                      pdf_lib.Container(
                        padding: const pdf_lib.EdgeInsets.all(4),
                        child: pdf_lib.Text(horas,
                            textAlign: pdf_lib.TextAlign.center,
                            style: const pdf_lib.TextStyle(
                              fontSize: 10,
                            )),
                      ),
                      pdf_lib.Container(
                        padding: const pdf_lib.EdgeInsets.all(4),
                        width: 20,
                        height: 20,
                        color: PdfColor.fromInt(cor.value),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pdf_lib.SizedBox(height: 20),
            pdf_lib.Table(
              border:
                  pdf_lib.TableBorder.all(color: PdfColors.grey, width: 0.5),
              children: calendarRows
                  .map((row) => pdf_lib.TableRow(children: row))
                  .toList(),
            ),
            pdf_lib.SizedBox(height: 20),
            pdf_lib.Text(
              'Carga horária mensal total: ${_calcularCargaHorariaMensal(provider)} horas',
              style: const pdf_lib.TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/calendario.pdf");
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
