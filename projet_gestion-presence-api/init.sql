
-- Initialisation de la base de données pour l'application de présence ESTC 2025
CREATE DATABASE IF NOT EXISTS estc2025;
USE estc2025;

-- 1. Table des Filières
CREATE TABLE IF NOT EXISTS Filiere (
    id_filiere INT PRIMARY KEY AUTO_INCREMENT,
    nom_filiere VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 2. Table des Étudiants
CREATE TABLE IF NOT EXISTS Etudiant (
    id_etudiant INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    id_filiere INT,
    CONSTRAINT fk_etudiant_filiere FOREIGN KEY (id_filiere) REFERENCES Filiere(id_filiere) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Table des Professeurs (Incluant le hash pour JWT)
CREATE TABLE IF NOT EXISTS Professeur (
    id_prof INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- 4. Table des Modules
CREATE TABLE IF NOT EXISTS Module (
    id_module INT PRIMARY KEY AUTO_INCREMENT,
    nom_module VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 5. Table des Séances (L'événement de cours)
CREATE TABLE IF NOT EXISTS Seance (
    id_seance INT PRIMARY KEY AUTO_INCREMENT,
    date_seance DATE NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin TIME NOT NULL,
    id_prof INT,
    id_module INT,
    id_filiere INT,
    CONSTRAINT fk_seance_prof FOREIGN KEY (id_prof) REFERENCES Professeur(id_prof),
    CONSTRAINT fk_seance_module FOREIGN KEY (id_module) REFERENCES Module(id_module),
    CONSTRAINT fk_seance_filiere FOREIGN KEY (id_filiere) REFERENCES Filiere(id_filiere)
) ENGINE=InnoDB;

-- 6. Table de Présence (Pointage)
CREATE TABLE IF NOT EXISTS Presence (
    id_presence INT PRIMARY KEY AUTO_INCREMENT,
    id_seance INT,
    id_etudiant INT,
    statut ENUM('Present', 'Absent', 'Retard', 'Justifie') DEFAULT 'Absent',
    commentaire TEXT,
    CONSTRAINT fk_presence_seance FOREIGN KEY (id_seance) REFERENCES Seance(id_seance) ON DELETE CASCADE,
    CONSTRAINT fk_presence_etudiant FOREIGN KEY (id_etudiant) REFERENCES Etudiant(id_etudiant) ON DELETE CASCADE,
    UNIQUE KEY unique_presence_etudiant_seance (id_seance, id_etudiant)
) ENGINE=InnoDB;

-- ==========================================
-- INSERTIONS DE TEST POUR LE DÉVELOPPEMENT
-- ==========================================

-- Insertion des filières
INSERT INTO Filiere (nom_filiere) VALUES ('DUT Informatique'), ('DUT GEII'), ('Licence Data Science');

-- Insertion des professeurs (Mot de passe par défaut : 'estc2025' - à hacher en Python plus tard)
INSERT INTO Professeur (nom, prenom, email, password_hash) 
VALUES ('Safhi', 'Pr', 'safhi@estc.ma', 'pbkdf2:sha256:250000$example_hash');

-- Insertion de quelques modules
INSERT INTO Module (nom_module) VALUES ('Développement Mobile (Flutter)'), ('Base de données SQL'), ('IoT & LoRaWAN');

-- Insertion d'étudiants de test pour la filière Info (ID 1)
INSERT INTO Etudiant (nom, prenom, id_filiere) VALUES 
('Alami', 'Ahmed', 1),
('Bennani', 'Sara', 1),
('Idrissi', 'Omar', 1),
('Mansouri', 'Laila', 1);

-- Création d'une séance fictive pour aujourd'hui
INSERT INTO Seance (date_seance, heure_debut, heure_fin, id_prof, id_module, id_filiere)
VALUES (CURDATE(), '08:30:00', '10:30:00', 1, 1, 1);
