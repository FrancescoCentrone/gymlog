import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/bia_report.dart';
import 'package:gym_log/presentation/state/bia_report_provider.dart';
import 'package:intl/intl.dart';

class BiaReportFormScreen extends ConsumerStatefulWidget {
  final BiaReport? initialReport;

  const BiaReportFormScreen({super.key, this.initialReport});

  @override
  ConsumerState<BiaReportFormScreen> createState() => _BiaReportFormScreenState();
}

class _BiaReportFormScreenState extends ConsumerState<BiaReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic info
  DateTime _recordDate = DateTime.now();
  final _weightController = TextEditingController();
  final _fitnessScoreController = TextEditingController();
  
  // Composition Analysis
  final _muscleController = TextEditingController();
  final _fatController = TextEditingController();
  final _tbwController = TextEditingController();
  final _ffmController = TextEditingController();
  
  // Obesity Analysis
  final _bmiController = TextEditingController();
  final _pbfController = TextEditingController();
  final _visceralFatController = TextEditingController();
  final _bmrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      final report = widget.initialReport!;
      _recordDate = report.recordDate;
      _weightController.text = report.weight.toString();
      _fitnessScoreController.text = report.fitnessScore.toString();
      
      _muscleController.text = report.composition.muscle.toString();
      _fatController.text = report.composition.fat.toString();
      _tbwController.text = report.composition.tbw.toString();
      _ffmController.text = report.composition.ffm.toString();
      
      _bmiController.text = report.obesity.bmi.toString();
      _pbfController.text = report.obesity.pbf.toString();
      _visceralFatController.text = report.obesity.visceralFatLevel.toString();
      _bmrController.text = report.obesity.bmr.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _fitnessScoreController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _tbwController.dispose();
    _ffmController.dispose();
    _bmiController.dispose();
    _pbfController.dispose();
    _visceralFatController.dispose();
    _bmrController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _recordDate) {
      setState(() {
        _recordDate = picked;
      });
    }
  }

  Future<void> _saveReport() async {
    if (_formKey.currentState!.validate()) {
      final report = BiaReport(
        id: widget.initialReport?.id,
        recordDate: _recordDate,
        weight: double.parse(_weightController.text),
        composition: CompositionAnalysis(
          muscle: double.parse(_muscleController.text),
          fat: double.parse(_fatController.text),
          tbw: double.parse(_tbwController.text),
          ffm: double.parse(_ffmController.text),
        ),
        obesity: ObesityAnalysis(
          bmi: double.parse(_bmiController.text),
          pbf: double.parse(_pbfController.text),
          visceralFatLevel: int.parse(_visceralFatController.text),
          bmr: double.parse(_bmrController.text),
        ),
        leanAnalysis: widget.initialReport?.leanAnalysis ?? [], 
        fatAnalysis: widget.initialReport?.fatAnalysis ?? [], 
        fitnessScore: int.parse(_fitnessScoreController.text),
      );

      try {
        final isUpdate = widget.initialReport?.id != null;

        if (isUpdate) {
          await ref.read(biaReportsProvider.notifier).updateBiaReport(report);
        } else {
          await ref.read(biaReportsProvider.notifier).addBiaReport(report);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpdate
                  ? 'Body composition record updated successfully' 
                  : 'Body composition record added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialReport != null ? 'Edit Body Composition' : 'Add Body Composition'),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Basic Information
                _buildSectionHeader('Basic Information'),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Record Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_recordDate)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight),
                const SizedBox(height: 16),
                _buildTextField(_fitnessScoreController, 'Fitness Score (0-100)', Icons.stars, isInteger: true),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Body Composition'),
                const SizedBox(height: 16),
                _buildTextField(_muscleController, 'Muscle Mass (kg)', Icons.fitness_center),
                const SizedBox(height: 16),
                _buildTextField(_fatController, 'Body Fat (kg)', Icons.pie_chart),
                const SizedBox(height: 16),
                _buildTextField(_tbwController, 'Total Body Water (L)', Icons.water_drop),
                const SizedBox(height: 16),
                _buildTextField(_ffmController, 'Fat-Free Mass (kg)', Icons.accessibility),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Obesity Analysis'),
                const SizedBox(height: 16),
                _buildTextField(_bmiController, 'BMI', Icons.straighten),
                const SizedBox(height: 16),
                _buildTextField(_pbfController, 'Body Fat %', Icons.percent),
                const SizedBox(height: 16),
                _buildTextField(_visceralFatController, 'Visceral Fat Level', Icons.warning_amber, isInteger: true),
                const SizedBox(height: 16),
                _buildTextField(_bmrController, 'BMR (kcal)', Icons.bolt),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Record',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                // Add an extra spacer for better scrolling comfort
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        final number = isInteger ? int.tryParse(value) : double.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }
}
