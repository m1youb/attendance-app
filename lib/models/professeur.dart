class Professeur {
  final int idProf;
  final String nom;
  final String prenom;
  final String email;

  Professeur({
    required this.idProf,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  factory Professeur.fromJson(Map<String, dynamic> json) => Professeur(
        idProf: json['id_prof'],
        nom: json['nom'],
        prenom: json['prenom'],
        email: json['email'],
      );
}
