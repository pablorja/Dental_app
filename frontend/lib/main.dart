import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const DentalApp());

class DentalApp extends StatelessWidget {
  const DentalApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DentalCare · Pacientes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)),
          scaffoldBackgroundColor: const Color(0xFFF5F8FA),
          fontFamily: 'Arial',
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF6F8FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4EAEE))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF087E8B), width: 1.5)),
          ),
        ),
        home: const PatientHomePage(),
      );
}

class Patient {
  const Patient({required this.id, required this.name, required this.document, required this.phone, this.email, this.notes, this.createdAt});
  final int id;
  final String name;
  final String document;
  final String phone;
  final String? email;
  final String? notes;
  final DateTime? createdAt;

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as int,
        name: json['nombre'] as String? ?? '',
        document: json['documento'] as String? ?? '',
        phone: json['telefono'] as String? ?? '',
        email: json['correo'] as String?,
        notes: json['notas'] as String?,
        createdAt: DateTime.tryParse(json['creadoEn'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {'nombre': name, 'documento': document, 'telefono': phone, 'correo': email, 'notas': notes};
}

class PatientApi {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get _baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5181/api/pacientes';
    return 'http://localhost:5181/api/pacientes';
  }

  static final _client = http.Client();

  static Future<List<Patient>> list() async {
    final response = await _client.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw ApiException(response.statusCode, _message(response));
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>)
        .map((item) => Patient.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<void> save(Map<String, dynamic> data, {int? id}) async {
    final uri = Uri.parse(_baseUrl + (id == null ? '' : '/$id'));
    final response = id == null
        ? await _client.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 12))
        : await _client.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 12));
    if (response.statusCode != 201 && response.statusCode != 204) throw ApiException(response.statusCode, _message(response));
  }

  static Future<void> delete(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/$id')).timeout(const Duration(seconds: 12));
    if (response.statusCode != 204) throw ApiException(response.statusCode, _message(response));
  }

  static String _message(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) return (body['mensaje'] ?? body['title'] ?? body['detail'] ?? 'Error al comunicarse con la API.').toString();
    } catch (_) {}
    return 'La API respondió con estado ${response.statusCode}.';
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});
  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  List<Patient> _patients = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  List<Patient> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((p) => '${p.name} ${p.document} ${p.phone} ${p.email ?? ''}'.toLowerCase().contains(query)).toList();
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PatientApi.list();
      if (mounted) setState(() { _patients = data; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = error is ApiException ? error.message : 'No se pudo conectar con la API. Verifica que esté encendida.'; _loading = false; });
    }
  }

  Future<void> _openForm([Patient? patient]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PatientFormDialog(patient: patient),
    );
    if (data == null) return;
    try {
      await PatientApi.save(data, id: patient?.id);
      await _load();
      if (mounted) _toast(patient == null ? 'Paciente creado correctamente.' : 'Paciente actualizado.');
    } catch (error) {
      if (mounted) _toast(error is ApiException ? error.message : 'No se pudo guardar el paciente.', isError: true);
    }
  }

  Future<void> _delete(Patient patient) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Eliminar paciente'),
      content: Text('¿Quieres eliminar a ${patient.name}? Esta acción no se puede deshacer.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar'))],
    ));
    if (confirmed != true) return;
    try {
      await PatientApi.delete(patient.id);
      await _load();
      if (mounted) _toast('Paciente eliminado.');
    } catch (error) {
      if (mounted) _toast(error is ApiException ? error.message : 'No se pudo eliminar el paciente.', isError: true);
    }
  }

  void _toast(String message, {bool isError = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message), behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFB42318) : const Color(0xFF176B5B),
      ));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    return Scaffold(
      body: Column(children: [
        _TopBar(onRefresh: _load),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20, vertical: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GESTIÓN DE PACIENTES', style: TextStyle(color: Color(0xFF087E8B), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pacientes', style: TextStyle(fontSize: wide ? 34 : 29, fontWeight: FontWeight.w800, color: const Color(0xFF18323B))),
                const SizedBox(height: 5), Text('Administra la información de tus pacientes.', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14)),
              ])),
              FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add, size: 19), label: const Text('Nuevo paciente'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ]),
            const SizedBox(height: 24),
            _SummaryCard(count: _patients.length),
            const SizedBox(height: 22),
            TextField(onChanged: (value) => setState(() => _query = value), decoration: InputDecoration(hintText: 'Buscar por nombre, documento, teléfono o correo', prefixIcon: const Icon(Icons.search), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { setState(() => _query = ''); }, icon: const Icon(Icons.close)))),
            const SizedBox(height: 15),
            Expanded(child: _content(wide)),
          ])),
        ))),
      ]),
    );
  }

  Widget _content(bool wide) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: _StateMessage(icon: Icons.cloud_off_outlined, title: 'No se pudo cargar la lista', message: _error!, action: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))));
    if (_filtered.isEmpty) return Center(child: _StateMessage(icon: Icons.person_search_outlined, title: _query.isEmpty ? 'Aún no hay pacientes' : 'No encontramos resultados', message: _query.isEmpty ? 'Agrega el primer paciente para empezar.' : 'Prueba con otro nombre o documento.', action: _query.isEmpty ? FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Agregar paciente')) : const SizedBox.shrink()));
    if (!wide) return RefreshIndicator(onRefresh: _load, child: ListView.separated(itemCount: _filtered.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (context, index) => _PatientCard(patient: _filtered[index], onEdit: () => _openForm(_filtered[index]), onDelete: () => _delete(_filtered[index]))));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7ECEF))),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15), decoration: const BoxDecoration(color: Color(0xFFF7FAFB), borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: const Row(children: [Expanded(flex: 3, child: _HeaderText('PACIENTE')), Expanded(flex: 2, child: _HeaderText('DOCUMENTO')), Expanded(flex: 2, child: _HeaderText('TELÉFONO')), Expanded(flex: 3, child: _HeaderText('CORREO')), SizedBox(width: 94)])),
        Expanded(child: ListView.separated(itemCount: _filtered.length, separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20), itemBuilder: (context, index) => _PatientRow(patient: _filtered[index], onEdit: () => _openForm(_filtered[index]), onDelete: () => _delete(_filtered[index])))),
      ]),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Container(height: 70, padding: const EdgeInsets.symmetric(horizontal: 28), decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE9EFF2)))), child: Row(children: [
    Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medical_services_outlined, color: Color(0xFF087E8B))),
    const SizedBox(width: 12), const Text('DentalCare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF18323B))), const SizedBox(width: 8), const Text('CLÍNICA DENTAL', style: TextStyle(fontSize: 10, letterSpacing: 1, color: Color(0xFF84949B), fontWeight: FontWeight.w700)),
    const Spacer(), IconButton(tooltip: 'Actualizar lista', onPressed: onRefresh, icon: const Icon(Icons.refresh, color: Color(0xFF607780))), const SizedBox(width: 10),
  ]));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE7ECEF))), child: Row(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE8F5F4), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.groups_2_outlined, color: Color(0xFF087E8B))), const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$count', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF18323B))), const Text('Pacientes registrados', style: TextStyle(fontSize: 12, color: Color(0xFF788A91)))]),
  ]));
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onEdit, required this.onDelete});
  final Patient patient; final VoidCallback onEdit; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE7ECEF)), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF18323B)))), _Actions(onEdit: onEdit, onDelete: onDelete)]),
    const SizedBox(height: 10), _DataLine(icon: Icons.badge_outlined, text: patient.document), _DataLine(icon: Icons.phone_outlined, text: patient.phone), if ((patient.email ?? '').isNotEmpty) _DataLine(icon: Icons.mail_outline, text: patient.email!),
  ]));
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient, required this.onEdit, required this.onDelete});
  final Patient patient; final VoidCallback onEdit; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13), child: Row(children: [
    Expanded(flex: 3, child: Row(children: [CircleAvatar(radius: 18, backgroundColor: const Color(0xFFE7F3F3), child: Text(patient.name.isEmpty ? '?' : patient.name.characters.first.toUpperCase(), style: const TextStyle(color: Color(0xFF087E8B), fontWeight: FontWeight.w700))), const SizedBox(width: 11), Expanded(child: Text(patient.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF28424A))))])),
    Expanded(flex: 2, child: Text(patient.document, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF52676F)))), Expanded(flex: 2, child: Text(patient.phone, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF52676F)))), Expanded(flex: 3, child: Text((patient.email ?? '').isEmpty ? '—' : patient.email!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF52676F)))), _Actions(onEdit: onEdit, onDelete: onDelete),
  ]));
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Editar paciente', onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF087E8B))), IconButton(tooltip: 'Eliminar paciente', onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFB42318)))]);
}

class _DataLine extends StatelessWidget {
  const _DataLine({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 7), child: Row(children: [Icon(icon, size: 16, color: const Color(0xFF82949B)), const SizedBox(width: 8), Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF52676F), fontSize: 13)))]));
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value); final String value;
  @override
  Widget build(BuildContext context) => Text(value, style: const TextStyle(fontSize: 10, letterSpacing: .8, color: Color(0xFF87969C), fontWeight: FontWeight.w800));
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.message, required this.action});
  final IconData icon; final String title; final String message; final Widget action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 45, color: const Color(0xFF91A4AA)), const SizedBox(height: 13), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF28424A))), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF788A91))), const SizedBox(height: 12), action])));
}

class PatientFormDialog extends StatefulWidget {
  const PatientFormDialog({super.key, this.patient}); final Patient? patient;
  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _document;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  @override
  void initState() { super.initState(); final p = widget.patient; _name = TextEditingController(text: p?.name ?? ''); _document = TextEditingController(text: p?.document ?? ''); _phone = TextEditingController(text: p?.phone ?? ''); _email = TextEditingController(text: p?.email ?? ''); _notes = TextEditingController(text: p?.notes ?? ''); }
  @override
  void dispose() { _name.dispose(); _document.dispose(); _phone.dispose(); _email.dispose(); _notes.dispose(); super.dispose(); }

  String? _required(String? value, String label, int max) { final text = value?.trim() ?? ''; if (text.isEmpty) return 'Ingresa $label.'; if (text.length > max) return 'Máximo $max caracteres.'; return null; }

  @override
  Widget build(BuildContext context) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740), child: Padding(padding: const EdgeInsets.all(26), child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(widget.patient == null ? 'Nuevo paciente' : 'Editar paciente', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF18323B)))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
    const SizedBox(height: 4), const Text('Completa los datos del paciente.', style: TextStyle(color: Color(0xFF788A91))), const SizedBox(height: 20),
    Flexible(child: SingleChildScrollView(child: Column(children: [
      TextFormField(controller: _name, maxLength: 100, decoration: const InputDecoration(labelText: 'Nombre completo *', prefixIcon: Icon(Icons.person_outline), counterText: ''), validator: (v) => _required(v, 'el nombre', 100)),
      const SizedBox(height: 14), TextFormField(controller: _document, maxLength: 30, decoration: const InputDecoration(labelText: 'Documento *', prefixIcon: Icon(Icons.badge_outlined), counterText: ''), validator: (v) => _required(v, 'el documento', 30)),
      const SizedBox(height: 14), TextFormField(controller: _phone, maxLength: 30, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono *', prefixIcon: Icon(Icons.phone_outlined), counterText: ''), validator: (v) => _required(v, 'el teléfono', 30)),
      const SizedBox(height: 14), TextFormField(controller: _email, maxLength: 150, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline), counterText: ''), validator: (v) { final text = v?.trim() ?? ''; if (text.isEmpty) return null; if (text.length > 150 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) return 'Escribe un correo válido.'; return null; }),
      const SizedBox(height: 14), TextFormField(controller: _notes, maxLength: 1000, maxLines: 3, decoration: const InputDecoration(labelText: 'Notas', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_outlined), counterText: ''), validator: (v) => (v?.length ?? 0) > 1000 ? 'Máximo 1000 caracteres.' : null),
    ]))),
    const SizedBox(height: 18), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), const SizedBox(width: 8), FilledButton.icon(onPressed: _submit, icon: Icon(widget.patient == null ? Icons.person_add_alt : Icons.save_outlined, size: 18), label: Text(widget.patient == null ? 'Crear paciente' : 'Guardar cambios'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)))]),
  ])))));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {'nombre': _name.text.trim(), 'documento': _document.text.trim(), 'telefono': _phone.text.trim(), 'correo': _email.text.trim().isEmpty ? null : _email.text.trim(), 'notas': _notes.text.trim().isEmpty ? null : _notes.text.trim()});
  }
}
