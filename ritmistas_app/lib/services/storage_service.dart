import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadProfilePicture(String userId) async {
    try {
      // 1. Selecionar Imagem
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,  // Tamanho ideal para perfil
        maxHeight: 512,
        imageQuality: 75, // Otimização
      );

      if (image == null) return null; // Usuário desistiu

      File file = File(image.path);

      // 2. Definir caminho no Storage (perfil/ID_DO_USER.jpg)
      // Usamos .jpg fixo pois convertemos na compressão, ou aceitamos o original.
      // O ideal é padronizar.
      Reference ref = _storage.ref().child('perfil/$userId.jpg');

      // 3. Upload
      print("Iniciando upload...");
      UploadTask task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await task;

      // 4. Pegar URL
      String url = await ref.getDownloadURL();
      print("Upload Sucesso! URL: $url");
      return url;

    } catch (e) {
      print('Erro no upload: $e');
      return null;
    }
  }
}