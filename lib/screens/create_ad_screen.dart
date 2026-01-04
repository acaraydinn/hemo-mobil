import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart'; // Merkezi sabitler eklendi
import 'home_screen.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- DEĞİŞKENLER ---
  List<String> cities = [];
  List<String> districts = [];
  List<dynamic> hospitals = [];

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedHospitalId;
  String? _selectedBloodType;
  String? _selectedProduct;

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientSurnameController = TextEditingController();
  final TextEditingController _patientTcController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: "1");
  final TextEditingController _contactPhoneController = TextEditingController();

  final List<String> _bloodTypes = ['A Rh+', 'A Rh-', 'B Rh+', 'B Rh-', 'AB Rh+', 'AB Rh-', '0 Rh+', '0 Rh-'];

  final List<String> _productTypes = [
    'Tam Kan',
    'Eritrosit Süspansiyonu',
    'Trombosit (Beyaz Kan)',
    'Taze Donmuş Plazma'
  ];

  final Map<String, String> _bloodTypeMapping = {
    'A Rh+': 'A+', 'A Rh-': 'A-', 'B Rh+': 'B+', 'B Rh-': 'B-',
    'AB Rh+': 'AB+', 'AB Rh-': 'AB-', '0 Rh+': '0+', '0 Rh-': '0-',
  };

  final Map<String, String> _productTypeMapping = {
    'Tam Kan': 'tam_kan',
    'Eritrosit Süspansiyonu': 'eritrosit',
    'Trombosit (Beyaz Kan)': 'trombosit',
    'Taze Donmuş Plazma': 'plazma',
  };

  @override
  void initState() {
    super.initState();
    _fetchCities();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPhone = prefs.getString('userPhone');
    if (savedPhone != null) {
      setState(() {
        _contactPhoneController.text = savedPhone;
      });
    }
  }

  // --- 1. ŞEHİRLERİ ÇEK ---
  Future<void> _fetchCities() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/cities/'));
      if (response.statusCode == 200) {
        setState(() {
          cities = List<String>.from(json.decode(utf8.decode(response.bodyBytes)));
        });
      }
    } catch (e) {
      print("Şehir hatası: $e");
    }
  }

  // --- 2. İLÇELERİ ÇEK ---
  Future<void> _fetchDistricts(String city) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/districts/?city=$city'));
      if (response.statusCode == 200) {
        setState(() {
          districts = List<String>.from(json.decode(utf8.decode(response.bodyBytes)));
          _selectedDistrict = null;
          _selectedHospitalId = null;
          hospitals = [];
        });
      }
    } catch (e) {
      print("İlçe hatası: $e");
    }
  }

  // --- 3. HASTANELERİ ÇEK ---
  Future<void> _fetchHospitals(String district) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/hospitals/?city=$_selectedCity&district=$district'));
      if (response.statusCode == 200) {
        setState(() {
          hospitals = json.decode(utf8.decode(response.bodyBytes));
          _selectedHospitalId = null;
        });
      }
    } catch (e) {
      print("Hastane hatası: $e");
    }
  }

  // --- İLANI GÖNDER ---
  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    String? userPhone = prefs.getString('userPhone');

    var selectedHospitalObj = hospitals.firstWhere((h) => h['id'].toString() == _selectedHospitalId);
    String hospitalName = selectedHospitalObj['name'];

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/blood-requests/'), // ApiConstants kullanımı
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_phone': userPhone,
          'patient_first_name': _patientNameController.text,
          'patient_last_name': _patientSurnameController.text,
          'patient_tc': _patientTcController.text,
          'city': _selectedCity,
          'district': _selectedDistrict,
          'hospital': hospitalName,
          'blood_type': _bloodTypeMapping[_selectedBloodType],
          'blood_product': _productTypeMapping[_selectedProduct],
          'amount': int.parse(_amountController.text),
          'contact_phone': _contactPhoneController.text,
          'transport_support': false,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlanınız başarıyla yayınlandı! Geçmiş olsun.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bir hata oluştu. Lütfen bilgileri kontrol edin.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Kan İhtiyacı Bildir", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Hasta Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildTextField(_patientNameController, "Hasta Adı")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_patientSurnameController, "Hasta Soyadı")),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(_patientTcController, "Hasta TC Kimlik (Gizli Tutulur)", isNumber: true, maxLength: 11),
              const SizedBox(height: 20),
              const Text("Hastane Bilgileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("İl Seçiniz"),
                value: _selectedCity,
                items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) {
                  setState(() => _selectedCity = value);
                  _fetchDistricts(value!);
                },
                validator: (val) => val == null ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("İlçe Seçiniz"),
                value: _selectedDistrict,
                items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (value) {
                  setState(() => _selectedDistrict = value);
                  _fetchHospitals(value!);
                },
                validator: (val) => val == null ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: _inputDecoration("Hastane Seçiniz"),
                value: _selectedHospitalId,
                items: hospitals.map((h) => DropdownMenuItem(
                    value: h['id'].toString(),
                    child: Text(h['name'], overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: (value) => setState(() => _selectedHospitalId = value),
                validator: (val) => val == null ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 20),
              const Text("İhtiyaç Detayları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Kan Grubu"),
                      value: _selectedBloodType,
                      items: _bloodTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setState(() => _selectedBloodType = value),
                      validator: (val) => val == null ? 'Zorunlu' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: _inputDecoration("Ürün Türü"),
                      value: _selectedProduct,
                      items: _productTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                      validator: (val) => val == null ? 'Zorunlu' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildTextField(_amountController, "Ünite", isNumber: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_contactPhoneController, "İletişim Numarası", isNumber: true, maxLength: 11),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("İLANI YAYINLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int? maxLength}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      decoration: _inputDecoration(label).copyWith(counterText: ""),
      validator: (val) => (val == null || val.isEmpty) ? 'Zorunlu' : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }
}