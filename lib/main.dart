import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MedicalQAApp());
}

class MedicalQAApp extends StatelessWidget {
  const MedicalQAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical QA Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MedicalQAScreen(),
    );
  }
}

class MedicalQAScreen extends StatefulWidget {
  const MedicalQAScreen({super.key});

  @override
  State<MedicalQAScreen> createState() => _MedicalQAScreenState();
}

class _MedicalQAScreenState extends State<MedicalQAScreen> {
  final TextEditingController _controller = TextEditingController();
  String _answer = '';
  String _model = '';
  bool _loading = false;
  bool _hasAnswer = false;

  // Your API Gateway URL
  static const String _apiUrl =
      'https://0e1fhj92j8.execute-api.us-east-1.amazonaws.com/predict';

  final List<String> _suggestions = [
    "What is the treatment for UTI in pregnancy? {'A': 'Ampicillin', 'B': 'Ceftriaxone', 'C': 'Ciprofloxacin', 'D': 'Doxycycline', 'E': 'Nitrofurantoin'}",
    "A patient with chest pain and elevated troponin. What is the diagnosis? {'A': 'GERD', 'B': 'MI', 'C': 'Anxiety', 'D': 'Costochondritis', 'E': 'Pericarditis'}",
    "What drug is used for malaria prophylaxis in pregnancy? {'A': 'Chloroquine', 'B': 'Mefloquine', 'C': 'Doxycycline', 'D': 'Primaquine', 'E': 'Atovaquone'}",
  ];

  Future<void> _askQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _loading = true;
      _hasAnswer = false;
      _answer = '';
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _answer = data['answer'] ?? 'No answer received';
          _model  = data['model'] ?? 'mistral-7b-medical-qa-qlora';
          _hasAnswer = true;
        });
      } else {
        setState(() {
          _answer = 'Error: ${response.statusCode}';
          _hasAnswer = true;
        });
      }
    } catch (e) {
      setState(() {
        _answer = 'Connection error: $e';
        _hasAnswer = true;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Medical QA Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Powered by fine-tuned Mistral-7B · QLoRA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input
                  const Text(
                    'Your medical question',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type your medical question here...',
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  // Suggestions
                  const SizedBox(height: 12),
                  const Text(
                    'Quick examples',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip('Cardiology', Icons.favorite),
                      _chip('Pharmacology', Icons.medication),
                      _chip('Obstetrics', Icons.pregnant_woman),
                    ],
                  ),

                  // Button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _askQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: Text(
                        _loading ? 'Asking...' : 'Ask Medical Assistant',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Answer card
                  if (_hasAnswer) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3EAF8)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1565C0),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ANSWER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1565C0),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _answer,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Response from fine-tuned Mistral-7B',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _model,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom nav
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.medical_services, 'Ask', true),
                _navItem(Icons.history, 'History', false),
                _navItem(Icons.info_outline, 'About', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _controller.text = _suggestions[
            ['Cardiology', 'Pharmacology', 'Obstetrics'].indexOf(label)];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF1565C0)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 22,
              color: active
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF999999)),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active
                  ? const Color(0xFF1565C0)
                  : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}