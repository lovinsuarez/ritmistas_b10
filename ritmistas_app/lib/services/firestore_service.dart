import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Função para salvar a URL da foto no perfil do usuário
  Future<void> updateUserPhoto(String userId, String photoUrl) async {
    try {
      // Vamos na coleção 'users', procuramos o documento do 'userId'
      // E atualizamos apenas o campo 'photoUrl'
      await _db.collection('users').doc(userId).set({
        'photoUrl': photoUrl,
        'updated_at': FieldValue.serverTimestamp(), // Marca a data/hora da mudança
      }, SetOptions(merge: true)); 
      
      // O 'merge: true' é vital: garante que não apagamos o resto dos dados do usuário
      
      print("URL salva no banco com sucesso!");
    } catch (e) {
      print("Erro ao salvar no banco: $e");
      throw e;
    }
  }
}