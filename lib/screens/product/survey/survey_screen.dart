// lib/screens/survey/survey_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/models/user_model.dart';
import 'package:impact_app/screens/product/survey/api/survey_api_service.dart';
import 'package:impact_app/screens/product/survey/model/survey_question_model.dart';
import 'package:impact_app/screens/product/survey/model/survey_response_model.dart';
import 'package:impact_app/themes/app_colors.dart';
import 'package:impact_app/utils/connectivity_utils.dart';
import 'package:impact_app/utils/logger.dart';
import 'package:impact_app/utils/session_manager.dart';
import 'package:uuid/uuid.dart'; // For generating submission_group_id


class SurveyScreen extends StatefulWidget {
  final String typeSurvey;

  const SurveyScreen({
    Key? key,
    required this.typeSurvey,
  }) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyApiService _apiService = SurveyApiService();
  final Logger _logger = Logger();
  final String _tag = 'SurveyScreen';
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = Uuid();


  List<SurveyQuestionModel> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Store answers: key is questionId
  Map<String, dynamic> _answers = {};
  Map<String, File?> _imageAnswers = {};
  Map<String, String?> _otherInputValues = {}; // For "Lainnya" fields
  Map<String, List<SurveyAnswerKeyModel>> _checkboxSelectedKeys = {}; // questionId -> list of selected keys

  User? _selectedUser = null;
  Store? _selectedStore = null;

  @override
  void initState() {
    super.initState();
    _initDataLocl();
  }

  Future<void> _initDataLocl() async {
    _selectedUser = await SessionManager().getCurrentUser();
    _selectedStore = await SessionManager().getStoreData();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() { _isLoading = true; });
    try {
      _questions = await _apiService.fetchSurveyQuestions(widget.typeSurvey, _selectedUser?.idpriciple ?? '');
      // Initialize answer map structures
      for (var q in _questions) {
        if (q.typeJawaban == 'checkbox') {
          _checkboxSelectedKeys[q.id] = [];
        }
      }
       _logger.d(_tag, "Fetched ${_questions.length} questions.");
    } catch (e) {
      _logger.e(_tag, "Error fetching questions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pertanyaan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _pickImage(String questionId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70); // Or ImageSource.gallery
    if (image != null) {
      setState(() {
        _imageAnswers[questionId] = File(image.path);
      });
    }
  }

  Widget _buildQuestionWidget(SurveyQuestionModel question) {
    switch (question.typeJawaban.toLowerCase()) {
      case 'dropdown':
        return _buildDropdownQuestion(question);
      case 'checkbox':
        return _buildCheckboxQuestion(question);
      case 'documentasi':
        return _buildDocumentasiQuestion(question);
      case 'essay':
        return _buildEssayQuestion(question);
      default:
        return Text('Tipe pertanyaan tidak didukung: ${question.typeJawaban}');
    }
  }

  Widget _buildDropdownQuestion(SurveyQuestionModel question) {
    SurveyAnswerKeyModel? selectedValue = _answers[question.id] as SurveyAnswerKeyModel?;
    bool showOtherField = selectedValue?.showsOtherField ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<SurveyAnswerKeyModel>(
          decoration: InputDecoration(labelText: question.pertanyaan, border: OutlineInputBorder()),
          value: selectedValue,
          items: question.keys.map((SurveyAnswerKeyModel keyItem) {
            return DropdownMenuItem<SurveyAnswerKeyModel>(
              value: keyItem,
              child: Text(keyItem.text),
            );
          }).toList(),
          onChanged: (SurveyAnswerKeyModel? newValue) {
            setState(() {
              _answers[question.id] = newValue;
              if (newValue != null && !newValue.showsOtherField) {
                _otherInputValues.remove(question.id); // Clear other value if not "Lainnya"
              }
            });
          },
          validator: (value) => value == null ? 'Mohon pilih jawaban' : null,
        ),
        if (showOtherField) SizedBox(height: 8),
        if (showOtherField)
          TextFormField(
            initialValue: _otherInputValues[question.id],
            decoration: InputDecoration(labelText: 'Keterangan Lainnya', border: OutlineInputBorder()),
            onChanged: (value) {
              _otherInputValues[question.id] = value;
            },
            validator: (value) => (value == null || value.isEmpty) ? 'Mohon isi keterangan lainnya' : null,
          ),
      ],
    );
  }

  Widget _buildCheckboxQuestion(SurveyQuestionModel question) {
     List<SurveyAnswerKeyModel> currentSelections = _checkboxSelectedKeys[question.id] ?? [];
     bool showOtherFieldForCheckbox = currentSelections.any((key) => key.showsOtherField);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.pertanyaan, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ...question.keys.map((keyItem) {
          return CheckboxListTile(
            title: Text(keyItem.text),
            value: currentSelections.any((k) => k.id == keyItem.id),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  if (!currentSelections.any((k) => k.id == keyItem.id)) {
                     currentSelections.add(keyItem);
                  }
                } else {
                  currentSelections.removeWhere((k) => k.id == keyItem.id);
                   if (keyItem.showsOtherField) {
                     _otherInputValues.remove(question.id); // Clear if "Lainnya" is deselected
                   }
                }
                 _checkboxSelectedKeys[question.id] = currentSelections;
              });
            },
          );
        }).toList(),
        if (showOtherFieldForCheckbox) SizedBox(height: 8),
        if (showOtherFieldForCheckbox)
          TextFormField(
            initialValue: _otherInputValues[question.id],
            decoration: InputDecoration(labelText: 'Keterangan Lainnya (Checkbox)', border: OutlineInputBorder()),
            onChanged: (value) {
              _otherInputValues[question.id] = value;
            },
             validator: (value) {
              if (showOtherFieldForCheckbox && (value == null || value.isEmpty)) {
                return 'Mohon isi keterangan lainnya';
              }
              return null;
            }
          ),
          // Validator for checkbox group (at least one selected) can be tricky,
          // often handled at the form submission level.
      ],
    );
  }

  Widget _buildDocumentasiQuestion(SurveyQuestionModel question) {
    File? imageFile = _imageAnswers[question.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.pertanyaan, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        if (imageFile != null)
          Image.file(imageFile, height: 150, width: 150, fit: BoxFit.cover),
        SizedBox(height: 8),
        ElevatedButton.icon(
          icon: Icon(Icons.camera_alt),
          label: Text(imageFile == null ? 'Ambil Foto' : 'Ganti Foto'),
          onPressed: () => _pickImage(question.id),
        ),
        // Validator for image can be handled at submission.
      ],
    );
  }

  Widget _buildEssayQuestion(SurveyQuestionModel question) {
    return TextFormField(
      decoration: InputDecoration(labelText: question.pertanyaan, border: OutlineInputBorder()),
      onChanged: (value) {
        _answers[question.id] = value;
      },
      maxLines: 3,
      validator: (value) => (value == null || value.isEmpty) ? 'Mohon isi jawaban' : null,
    );
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi semua jawaban yang diperlukan.')),
      );
      return;
    }
    // Additional validation for checkbox (at least one) and documentasi (image present)
    for (var q in _questions) {
        if (q.typeJawaban.toLowerCase() == 'checkbox') {
            if ((_checkboxSelectedKeys[q.id] ?? []).isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mohon pilih setidaknya satu opsi untuk: ${q.pertanyaan}')),
                );
                return;
            }
        } else if (q.typeJawaban.toLowerCase() == 'documentasi') {
            if (_imageAnswers[q.id] == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mohon unggah dokumen untuk: ${q.pertanyaan}')),
                );
                return;
            }
        }
    }


    setState(() { _isSubmitting = true; });

    String submissionGroupId = _uuid.v4();
    String submissionTime = DateTime.now().toIso8601String();
    List<SurveyResponseLocalModel> responsesToSubmit = [];

    for (SurveyQuestionModel q in _questions) {
      String? otherVal = _otherInputValues[q.id];

      if (q.typeJawaban.toLowerCase() == 'dropdown') {
        SurveyAnswerKeyModel? selectedKey = _answers[q.id] as SurveyAnswerKeyModel?;
        if (selectedKey != null) {
          responsesToSubmit.add(SurveyResponseLocalModel(
            submissionGroupId: submissionGroupId,
            idUser: _selectedUser?.idLogin ?? "", // Replace with actual user ID
            idPrinciple: _selectedUser?.idpriciple ?? "",
            idOutlet: _selectedStore?.idOutlet ?? "",
            outletName: _selectedStore?.nama ?? "",
            idSoal: q.id,
            pertanyaan: q.pertanyaan,
            typeJawaban: q.typeJawaban,
            idJawabanKey: selectedKey.id,
            jawabanText: selectedKey.text,
            valueLainnya: selectedKey.showsOtherField ? otherVal : null,
            tglSubmission: submissionTime,
          ));
        }
      } else if (q.typeJawaban.toLowerCase() == 'checkbox') {
        List<SurveyAnswerKeyModel> selectedKeys = _checkboxSelectedKeys[q.id] ?? [];
        for (var keyItem in selectedKeys) {
           responsesToSubmit.add(SurveyResponseLocalModel(
            submissionGroupId: submissionGroupId,
            idUser: _selectedUser?.idLogin ?? "",
            idPrinciple: _selectedUser?.idpriciple ?? "",
            idOutlet: _selectedStore?.idOutlet ?? "",
            outletName: _selectedStore?.nama ?? "",
            idSoal: q.id,
            pertanyaan: q.pertanyaan, // Or a more general "Checkbox response"
            typeJawaban: q.typeJawaban,
            idJawabanKey: keyItem.id,
            jawabanText: keyItem.text,
            valueLainnya: keyItem.showsOtherField ? otherVal : null,
            tglSubmission: submissionTime,
          ));
        }
      } else if (q.typeJawaban.toLowerCase() == 'documentasi') {
        File? imageFile = _imageAnswers[q.id];
        if (imageFile != null) {
          responsesToSubmit.add(SurveyResponseLocalModel(
            submissionGroupId: submissionGroupId,
            idUser: _selectedUser?.idLogin ?? "",
            idPrinciple: _selectedUser?.idpriciple ?? "",
            idOutlet: _selectedStore?.idOutlet ?? "",
            outletName: _selectedStore?.nama ?? "",
            idSoal: q.id,
            pertanyaan: q.pertanyaan,
            typeJawaban: q.typeJawaban,
            imagePath: imageFile.path,
            tglSubmission: submissionTime,
          ));
        }
      } else if (q.typeJawaban.toLowerCase() == 'essay') {
        String? essayText = _answers[q.id] as String?;
        if (essayText != null && essayText.isNotEmpty) {
           responsesToSubmit.add(SurveyResponseLocalModel(
            submissionGroupId: submissionGroupId,
            idUser: _selectedUser?.idLogin ?? "",
            idPrinciple: _selectedUser?.idpriciple ?? "",
            idOutlet: _selectedStore?.idOutlet ?? "",
            outletName: _selectedStore?.nama ?? "",
            idSoal: q.id,
            pertanyaan: q.pertanyaan,
            typeJawaban: q.typeJawaban,
            jawabanText: essayText,
            tglSubmission: submissionTime,
          ));
        }
      }
    }
    
    _logger.d(_tag, "Prepared ${responsesToSubmit.length} responses for submission group $submissionGroupId");

    // Try online submission first, then fallback to offline
    // For simplicity, this example directly saves offline.
    // A more robust solution would check connectivity.
    bool allSubmittedOnline = true;
    // TODO: Check internet connectivity
    // bool isConnected = await checkInternetConnectivity();
    bool isConnected = await ConnectivityUtils.checkInternetConnection(); // Assume offline for this example to test saving

    if (isConnected) {
        _logger.i(_tag, "Attempting online submission for ${responsesToSubmit.length} responses.");
        for (var responseModel in responsesToSubmit) {
            bool success = await _apiService.submitSurveyResponse(responseModel);
            if (!success) {
                allSubmittedOnline = false;
                _logger.w(_tag, "Failed to submit response for soal ${responseModel.idSoal} online. Will save offline.");
                await _apiService.saveSurveyResponseOffline(responseModel); // Save this specific one offline
            } else {
                 _logger.i(_tag, "Successfully submitted response for soal ${responseModel.idSoal} online.");
            }
        }
    } else {
        _logger.i(_tag, "No internet / Choosing offline. Saving all ${responsesToSubmit.length} responses offline.");
        allSubmittedOnline = false; // Since we are saving offline
        for (var responseModel in responsesToSubmit) {
            try {
                await _apiService.saveSurveyResponseOffline(responseModel);
            } catch (e) {
                 _logger.e(_tag, "Error saving response for soal ${responseModel.idSoal} offline: $e");
                 // Handle individual save error if necessary
            }
        }
    }


    setState(() { _isSubmitting = false; });

    if (allSubmittedOnline && isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Survey berhasil dikirim!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Indicate success
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Survey disimpan offline. Akan dikirim saat ada koneksi.'), backgroundColor: Colors.orange),
      );
      Navigator.of(context).pop(false); // Indicate saved offline
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Survey (${widget.typeSurvey})'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(child: Text('Tidak ada pertanyaan survey untuk saat ini.'))
              : Form(
                  key: _formKey,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.0),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return Material( // Wrap with Material for elevation and theming
                        elevation: 1.0,
                        borderRadius: BorderRadius.circular(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _buildQuestionWidget(_questions[index]),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 20),
                  ),
                ),
      bottomNavigationBar: _questions.isNotEmpty && !_isLoading
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: _isSubmitting ? SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) : Icon(Icons.send),
                label: Text(_isSubmitting ? 'MENGIRIM...' : 'KIRIM SURVEY'),
                onPressed: _isSubmitting ? null : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            )
          : null,
    );
  }
}
