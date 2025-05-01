class Etiqueta {
  final String nome;
  final double alturaCm;
  final double larguraCm;
  final double margemSuperiorCm;
  final double margemInferiorCm;
  final double margemEsquerdaCm;
  final double margemDireitaCm;
  final double espacoEntreEtiquetasCm;
  final int etiquetasPorFolha;
  final bool personalizada;

  Etiqueta({
    required this.nome,
    required this.alturaCm,
    required this.larguraCm,
    required this.margemSuperiorCm,
    required this.margemInferiorCm,
    required this.margemEsquerdaCm,
    required this.margemDireitaCm,
    required this.espacoEntreEtiquetasCm,
    required this.etiquetasPorFolha,
    this.personalizada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'alturaCm': alturaCm,
      'larguraCm': larguraCm,
      'margemSuperiorCm': margemSuperiorCm,
      'margemInferiorCm': margemInferiorCm,
      'margemEsquerdaCm': margemEsquerdaCm,
      'margemDireitaCm': margemDireitaCm,
      'espacoEntreEtiquetasCm': espacoEntreEtiquetasCm,
      'etiquetasPorFolha': etiquetasPorFolha,
      'personalizada': personalizada ? 1 : 0,
    };
  }

  factory Etiqueta.fromMap(Map<String, dynamic> map) {
    return Etiqueta(
      nome: map['nome'],
      alturaCm: map['alturaCm'],
      larguraCm: map['larguraCm'],
      margemSuperiorCm: map['margemSuperiorCm'],
      margemInferiorCm: map['margemInferiorCm'],
      margemEsquerdaCm: map['margemEsquerdaCm'],
      margemDireitaCm: map['margemDireitaCm'],
      espacoEntreEtiquetasCm: map['espacoEntreEtiquetasCm'],
      etiquetasPorFolha: map['etiquetasPorFolha'],
      personalizada: map['personalizada'] == 1,
    );
  }

  Etiqueta copyWith({
    String? nome,
    double? alturaCm,
    double? larguraCm,
    double? margemSuperiorCm,
    double? margemInferiorCm,
    double? margemEsquerdaCm,
    double? margemDireitaCm,
    double? espacoEntreEtiquetasCm,
    int? etiquetasPorFolha,
    bool? personalizada,
  }) {
    return Etiqueta(
      nome: nome ?? this.nome,
      alturaCm: alturaCm ?? this.alturaCm,
      larguraCm: larguraCm ?? this.larguraCm,
      margemSuperiorCm: margemSuperiorCm ?? this.margemSuperiorCm,
      margemInferiorCm: margemInferiorCm ?? this.margemInferiorCm,
      margemEsquerdaCm: margemEsquerdaCm ?? this.margemEsquerdaCm,
      margemDireitaCm: margemDireitaCm ?? this.margemDireitaCm,
      espacoEntreEtiquetasCm: espacoEntreEtiquetasCm ?? this.espacoEntreEtiquetasCm,
      etiquetasPorFolha: etiquetasPorFolha ?? this.etiquetasPorFolha,
      personalizada: personalizada ?? this.personalizada,
    );
  }
}
