class Module {
  final int idModule;
  final String nomModule;

  Module({required this.idModule, required this.nomModule});

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        idModule: json['id_module'],
        nomModule: json['nom_module'],
      );
}
