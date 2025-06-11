import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final FirebaseFirestore firestore;

  UserProvider({FirebaseFirestore? firestoreInstance})
      : firestore = firestoreInstance ?? FirebaseFirestore.instance;

  UserModel? get user => _user;

  /// Carrega o usuário do Firestore
  Future<void> loadUser(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      _user = UserModel.fromDocument(doc);
      notifyListeners();
    }
  }

  /// Define o usuário e salva/atualiza no Firestore
  Future<void> setUser(UserModel user) async {
    _user = user;
    notifyListeners();
    await firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Atualiza apenas o e-mail no Firestore e local
  Future<void> updateEmail(String email) async {
    if (_user != null) {
      _user = _user!.copyWith(email: email);
      notifyListeners();
      await firestore.collection('users').doc(_user!.id).update({'email': email});
    }
  }

  /// Atualiza apenas o celular no Firestore e local
  Future<void> updateCelular(String celular) async {
    if (_user != null) {
      _user = _user!.copyWith(celular: celular);
      notifyListeners();
      await firestore.collection('users').doc(_user!.id).update({'celular': celular});
    }
  }

  /// Atualiza apenas o avatar no Firestore e local
  Future<void> updateAvatar(String url) async {
    if (_user != null) {
      _user = _user!.copyWith(avatarUrl: url);
      notifyListeners();
      await firestore.collection('users').doc(_user!.id).update({'avatarUrl': url});
    }
  }
}