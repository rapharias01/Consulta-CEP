import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta CEP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ConsultaCEPScreen(),
    );
  }
}

class ConsultaCEPScreen extends StatefulWidget {
  const ConsultaCEPScreen({super.key});

  @override
  State<ConsultaCEPScreen> createState() => _ConsultaCEPScreenState();
}

class _ConsultaCEPScreenState extends State<ConsultaCEPScreen> {
  final TextEditingController _cepController = TextEditingController();
  Map<String, dynamic> _cepInfo = {};
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _consultarCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cep.length != 8) {
      setState(() {
        _errorMessage = 'CEP deve ter 8 dígitos';
        _cepInfo = {};
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('erro')) {
          setState(() {
            _errorMessage = 'CEP não encontrado';
            _cepInfo = {};
          });
        } else {
          setState(() {
            _cepInfo = data;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erro na consulta: ${response.statusCode}';
          _cepInfo = {};
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro na conexão: $e';
        _cepInfo = {};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta CEP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cepController,
              decoration: const InputDecoration(
                labelText: 'Digite o CEP',
                hintText: 'Ex: 01001000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 9,
              onChanged: (value) {
                if (value.length == 5 && !value.contains('-')) {
                  _cepController.text = '$value-';
                  _cepController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _cepController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              )
            else if (_cepInfo.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CEP ${_cepInfo['cep']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_cepInfo['logradouro'] ?? ''}\n'
                      '${_cepInfo['bairro'] ?? ''}, '
                      '${_cepInfo['localidade'] ?? ''} - '
                      '${_cepInfo['uf'] ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _consultarCEP,
        tooltip: 'Consultar CEP',
        child: const Icon(Icons.search),
      ),
    );
  }

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }
}