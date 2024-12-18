import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(
    MaterialApp(
      home: PredictPage(),
      debugShowCheckedModeBanner: false, // Supprime la bannière "debug"
    ),
  );
}

class PredictPage extends StatefulWidget {
  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  File? _image; // Fichier de l'image capturée
  final picker = ImagePicker(); // Pour accéder à la caméra
  List<Map<String, dynamic>> _faces = []; // Liste des visages détectés

  // Méthode pour capturer une image
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _faces = []; // Réinitialise les résultats précédents
      });
    }
  }

  // Méthode pour envoyer une image au serveur
  Future<void> _sendImageToServer() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez capturer une image d'abord.")),
      );
      return;
    }

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://192.168.1.35:5000/predict"), // Remplacez par l'adresse de votre serveur
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);

        if (data.containsKey('faces')) {
          setState(() {
            _faces = List<Map<String, dynamic>>.from(data['faces']); // Stocke les résultats
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${data['error']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur du serveur : ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // Méthode pour afficher l'image avec les résultats de détection
  Widget _buildImageWithFaces() {
    if (_image == null) {
      return Text("Aucune image sélectionnée.");
    }

    return Stack(
      children: [
        Image.file(_image!), // Affiche l'image capturée
        if (_faces.isNotEmpty)
          ..._faces.map((face) {
            final box = face['box'];
            final label = face['label'];
            return Positioned(
              left: box[0].toDouble(),
              top: box[1].toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détection de Visages"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildImageWithFaces(), // Affiche l'image et les résultats
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Prendre une photo"),
                ),
                ElevatedButton(
                  onPressed: _sendImageToServer,
                  child: Text("Envoyer au serveur"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
