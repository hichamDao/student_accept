import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: PredictPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PredictPage extends StatefulWidget {
  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  File? _image;
  final picker = ImagePicker();
  String _predictionResult = '';

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendImageToServer() async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://192.168.1.35:5000/predict"),
    );
    request.files.add(
      await http.MultipartFile.fromPath('image', _image!.path),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);

        setState(() {
          _predictionResult = data['label'];
        });
      } else {
        setState(() {
          _predictionResult = "Erreur: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = "Erreur de communication";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Prédiction")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image == null
              ? Text("Aucune image sélectionnée.")
              : Image.file(_image!),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text("Prendre une photo"),
          ),
          ElevatedButton(
            onPressed: _sendImageToServer,
            child: Text("Envoyer au serveur"),
          ),
          SizedBox(height: 20),
          Text(
            _predictionResult.isEmpty ? "Aucune prédiction" : "Résultat : $_predictionResult",
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
