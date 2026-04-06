class Presence {
  final int idPresence;
  final int idSeance;
  final int idEtudiant;
  final String statut;
  final String commentaire;

  Presence({
    required this.idPresence,
    required this.idSeance,
    required this.idEtudiant,
    required this.statut,
    required this.commentaire,
  });

  factory Presence.fromJson(Map<String, dynamic> json) => Presence(
        idPresence: json['id_presence'],
        idSeance: json['id_seance'],
        idEtudiant: json['id_etudiant'],
        statut: json['statut'] ?? 'Absent',
        commentaire: json['commentaire'] ?? '',
      );
}
