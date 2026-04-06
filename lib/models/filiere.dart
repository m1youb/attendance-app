class Filiere {
  final int idFiliere;
  final String nomFiliere;

  Filiere({required this.idFiliere, required this.nomFiliere});

  factory Filiere.fromJson(Map<String, dynamic> json) => Filiere(
        idFiliere: json['id_filiere'],
        nomFiliere: json['nom_filiere'],
      );
}
