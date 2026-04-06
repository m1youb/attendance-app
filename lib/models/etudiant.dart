class Etudiant {
  final int idEtudiant;
  final String nom;
  final String prenom;
  final int idFiliere;

  Etudiant({
    required this.idEtudiant,
    required this.nom,
    required this.prenom,
    required this.idFiliere,
  });

  factory Etudiant.fromJson(Map<String, dynamic> json) => Etudiant(
        idEtudiant: json['id_etudiant'],
        nom: json['nom'],
        prenom: json['prenom'],
        idFiliere: json['id_filiere'],
      );
}
