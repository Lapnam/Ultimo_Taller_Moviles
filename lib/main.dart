import 'package:flutter/material.dart';
import 'covid_api.dart';
import 'covid_data.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: Colors.teal,
      useMaterial3: true,
    ),
    home: const HomePage(),
  ));
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const countries = [
    'Colombia',
    'Mexico',
    'Argentina',
    'Peru',
    'Chile',
    'Spain',
    'USA',
  ];

  String selected = 'Colombia';
  late Future<CovidData> future = fetchCountry(selected);

  void _reload() {
    setState(() {
      future = fetchCountry(selected);
    });
  }

  Future<void> _notify(CovidData d) async {
    await NotificationService.show(
      title: 'COVID-19: ${d.country}',
      body: 'Casos: ${d.cases} | Muertes: ${d.deaths} | Hoy: ${d.todayCases}',
    );
  }

  // Una fila con icono, título y valor (se reutiliza 5 veces)
  Widget _fila(IconData icono, String titulo, String valor) {
    return ListTile(
      dense: true,
      leading: Icon(icono, color: Theme.of(context).colorScheme.primary),
      title: Text(titulo),
      trailing: Text(
        valor,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos COVID-19'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    items: countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      selected = value;
                      _reload();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<CovidData>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No se pudo consultar: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  final d = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        d.country,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            _fila(Icons.coronavirus, 'Casos acumulados', '${d.cases}'),
                            _fila(Icons.trending_up, 'Casos del día', '${d.todayCases}'),
                            _fila(Icons.heart_broken, 'Muertes acumuladas', '${d.deaths}'),
                            _fila(Icons.today, 'Muertes del día', '${d.todayDeaths}'),
                            _fila(Icons.favorite, 'Recuperados', '${d.recovered}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Actualizado: ${formatDate(d.updated)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _notify(d),
                        icon: const Icon(Icons.notifications),
                        label: const Text('Enviar notificación'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}