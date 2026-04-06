class Seance {
  final int idSeance;
  final String dateSeance;
  final String heureDebut;
  final String heureFin;
  final int idProf;
  final int idModule;
  final int idFiliere;

  Seance({
    required this.idSeance,
    required this.dateSeance,
    required this.heureDebut,
    required this.heureFin,
    required this.idProf,
    required this.idModule,
    required this.idFiliere,
  });

  factory Seance.fromJson(Map<String, dynamic> json) => Seance(
        idSeance: json['id_seance'],
        dateSeance: json['date_seance'],
        heureDebut: json['heure_debut'],
        heureFin: json['heure_fin'],
        idProf: json['id_prof'],
        idModule: json['id_module'],
        idFiliere: json['id_filiere'],
      );
}
