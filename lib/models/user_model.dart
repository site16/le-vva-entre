import 'package:flutter/foundation.dart';

enum EntregadorTipo {
  motoboy,
  biker,
}

@immutable
class UserModel {
  final String id;
  final String nomeCompleto;
  final String cpf;
  final String nascimento;
  final String celular;
  final String email;
  final String avatarUrl;
  final String avaliacao;
  final EntregadorTipo tipo;

  // Motoboy fields
  final String? cnh;
  final String? fotoMotoUrl;
  final String? modeloMoto;
  final String? corMoto;
  final String? placaMoto;
  final String? renavamMoto;

  // Biker fields
  final String? docFotoUrl;
  final String? cnhOpcional;

  // Construtor para motoboy
  const UserModel.motoboy({
    required this.id,
    required this.nomeCompleto,
    required this.cpf,
    required this.nascimento,
    required this.celular,
    required this.email,
    required this.avatarUrl,
    required this.avaliacao,
    required this.cnh,
    required this.fotoMotoUrl,
    required this.modeloMoto,
    required this.corMoto,
    required this.placaMoto,
    required this.renavamMoto,
  })  : tipo = EntregadorTipo.motoboy,
        docFotoUrl = null,
        cnhOpcional = null;

  // Construtor para biker
  const UserModel.biker({
    required this.id,
    required this.nomeCompleto,
    required this.cpf,
    required this.nascimento,
    required this.celular,
    required this.email,
    required this.avatarUrl,
    required this.avaliacao,
    required this.docFotoUrl,
    this.cnhOpcional,
  })  : tipo = EntregadorTipo.biker,
        cnh = null,
        fotoMotoUrl = null,
        modeloMoto = null,
        corMoto = null,
        placaMoto = null,
        renavamMoto = null;

  // fromMap ou fromDocument pode ser ajustado conforme seu Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final tipoString = map['tipo'] as String? ?? 'motoboy';
    final tipo = tipoString == 'biker' ? EntregadorTipo.biker : EntregadorTipo.motoboy;
    if (tipo == EntregadorTipo.motoboy) {
      return UserModel.motoboy(
        id: map['id'] ?? '',
        nomeCompleto: map['nomeCompleto'] ?? '',
        cpf: map['cpf'] ?? '',
        nascimento: map['nascimento'] ?? '',
        celular: map['celular'] ?? '',
        email: map['email'] ?? '',
        avatarUrl: map['avatarUrl'] ?? '',
        avaliacao: map['avaliacao'] ?? '',
        cnh: map['cnh'],
        fotoMotoUrl: map['fotoMotoUrl'],
        modeloMoto: map['modeloMoto'],
        corMoto: map['corMoto'],
        placaMoto: map['placaMoto'],
        renavamMoto: map['renavamMoto'],
      );
    } else {
      return UserModel.biker(
        id: map['id'] ?? '',
        nomeCompleto: map['nomeCompleto'] ?? '',
        cpf: map['cpf'] ?? '',
        nascimento: map['nascimento'] ?? '',
        celular: map['celular'] ?? '',
        email: map['email'] ?? '',
        avatarUrl: map['avatarUrl'] ?? '',
        avaliacao: map['avaliacao'] ?? '',
        docFotoUrl: map['docFotoUrl'],
        cnhOpcional: map['cnhOpcional'],
      );
    }
  }

  factory UserModel.fromDocument(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'nomeCompleto': nomeCompleto,
      'cpf': cpf,
      'nascimento': nascimento,
      'celular': celular,
      'email': email,
      'avatarUrl': avatarUrl,
      'avaliacao': avaliacao,
      'tipo': tipo == EntregadorTipo.motoboy ? 'motoboy' : 'biker',
    };

    if (tipo == EntregadorTipo.motoboy) {
      if (cnh != null) map['cnh'] = cnh;
      if (fotoMotoUrl != null) map['fotoMotoUrl'] = fotoMotoUrl;
      if (modeloMoto != null) map['modeloMoto'] = modeloMoto;
      if (corMoto != null) map['corMoto'] = corMoto;
      if (placaMoto != null) map['placaMoto'] = placaMoto;
      if (renavamMoto != null) map['renavamMoto'] = renavamMoto;
    } else {
      if (docFotoUrl != null) map['docFotoUrl'] = docFotoUrl;
      if (cnhOpcional != null) map['cnhOpcional'] = cnhOpcional;
    }
    return map;
  }

  // Método copyWith para ambos os tipos
  UserModel copyWith({
    String? id,
    String? nomeCompleto,
    String? cpf,
    String? nascimento,
    String? celular,
    String? email,
    String? avatarUrl,
    String? avaliacao,
    String? cnh,
    String? fotoMotoUrl,
    String? modeloMoto,
    String? corMoto,
    String? placaMoto,
    String? renavamMoto,
    String? docFotoUrl,
    String? cnhOpcional,
  }) {
    if (tipo == EntregadorTipo.motoboy) {
      return UserModel.motoboy(
        id: id ?? this.id,
        nomeCompleto: nomeCompleto ?? this.nomeCompleto,
        cpf: cpf ?? this.cpf,
        nascimento: nascimento ?? this.nascimento,
        celular: celular ?? this.celular,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avaliacao: avaliacao ?? this.avaliacao,
        cnh: cnh ?? this.cnh!,
        fotoMotoUrl: fotoMotoUrl ?? this.fotoMotoUrl!,
        modeloMoto: modeloMoto ?? this.modeloMoto!,
        corMoto: corMoto ?? this.corMoto!,
        placaMoto: placaMoto ?? this.placaMoto!,
        renavamMoto: renavamMoto ?? this.renavamMoto!,
      );
    } else {
      return UserModel.biker(
        id: id ?? this.id,
        nomeCompleto: nomeCompleto ?? this.nomeCompleto,
        cpf: cpf ?? this.cpf,
        nascimento: nascimento ?? this.nascimento,
        celular: celular ?? this.celular,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avaliacao: avaliacao ?? this.avaliacao,
        docFotoUrl: docFotoUrl ?? this.docFotoUrl!,
        cnhOpcional: cnhOpcional ?? this.cnhOpcional,
      );
    }
  }
}