from datetime import date, datetime, time, timedelta
import os
from typing import List

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy import Column, Date, Enum, ForeignKey, Integer, String, Time, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+pymysql://estc:estc2025@db/estc2025?charset=utf8mb4",
)
SECRET_KEY = os.getenv("JWT_SECRET", "estc_secret_key_2025")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

app = FastAPI(title="ESTC Presence API 2025")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Filiere(Base):
    __tablename__ = "Filiere"

    id_filiere = Column(Integer, primary_key=True, index=True)
    nom_filiere = Column(String(100))


class Etudiant(Base):
    __tablename__ = "Etudiant"

    id_etudiant = Column(Integer, primary_key=True, index=True)
    nom = Column(String(50))
    prenom = Column(String(50))
    id_filiere = Column(Integer, ForeignKey("Filiere.id_filiere"))


class Professeur(Base):
    __tablename__ = "Professeur"

    id_prof = Column(Integer, primary_key=True, index=True)
    nom = Column(String(50))
    prenom = Column(String(50))
    email = Column(String(100), unique=True)
    password_hash = Column(String(255))


class Seance(Base):
    __tablename__ = "Seance"

    id_seance = Column(Integer, primary_key=True, index=True)
    date_seance = Column(Date)
    heure_debut = Column(Time)
    heure_fin = Column(Time)
    id_prof = Column(Integer, ForeignKey("Professeur.id_prof"))
    id_module = Column(Integer, ForeignKey("Module.id_module"))
    id_filiere = Column(Integer, ForeignKey("Filiere.id_filiere"))


class ModuleModel(Base):
    __tablename__ = "Module"

    id_module = Column(Integer, primary_key=True, index=True)
    nom_module = Column(String(100))


class Presence(Base):
    __tablename__ = "Presence"

    id_presence = Column(Integer, primary_key=True, index=True)
    id_seance = Column(Integer, ForeignKey("Seance.id_seance"))
    id_etudiant = Column(Integer, ForeignKey("Etudiant.id_etudiant"))
    statut = Column(
        Enum("Present", "Absent", "Retard", "Justifie"),
        default="Absent",
    )
    commentaire = Column(String(500))


class PresenceRecord(BaseModel):
    id_etudiant: int
    statut: str
    commentaire: str = ""


class PresenceSubmission(BaseModel):
    id_seance: int
    records: List[PresenceRecord]


class ModulePayload(BaseModel):
    nom_module: str


class EtudiantPayload(BaseModel):
    nom: str
    prenom: str
    id_filiere: int


class SeancePayload(BaseModel):
    date_seance: str
    heure_debut: str
    heure_fin: str
    id_module: int
    id_filiere: int


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_professeur(token: str, db: Session) -> Professeur:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Token invalide") from exc

    user = db.query(Professeur).filter(Professeur.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Professeur introuvable")

    return user


def parse_iso_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Date invalide") from exc


def parse_iso_time(value: str) -> time:
    try:
        return time.fromisoformat(value)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Heure invalide") from exc


@app.post("/token")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = db.query(Professeur).filter(Professeur.email == form_data.username).first()
    if not user or form_data.password != "estc2025":
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect")

    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/me")
def read_current_professeur(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
):
    user = get_current_professeur(token, db)
    return {
        "id_prof": user.id_prof,
        "nom": user.nom,
        "prenom": user.prenom,
        "email": user.email,
    }


@app.get("/filieres")
def read_filieres(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    return db.query(Filiere).all()


@app.post("/filieres")
def create_filiere(
    nom: str, db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
):
    new_filiere = Filiere(nom_filiere=nom)
    db.add(new_filiere)
    db.commit()
    db.refresh(new_filiere)
    return new_filiere


@app.get("/modules")
def read_modules(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    return db.query(ModuleModel).order_by(ModuleModel.nom_module.asc()).all()


@app.post("/modules")
def create_module(
    payload: ModulePayload,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    module = ModuleModel(nom_module=payload.nom_module)
    db.add(module)
    db.commit()
    db.refresh(module)
    return module


@app.put("/modules/{id_module}")
def update_module(
    id_module: int,
    payload: ModulePayload,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    module = db.query(ModuleModel).filter(ModuleModel.id_module == id_module).first()
    if not module:
        raise HTTPException(status_code=404, detail="Module introuvable")

    module.nom_module = payload.nom_module
    db.commit()
    db.refresh(module)
    return module


@app.delete("/modules/{id_module}")
def delete_module(
    id_module: int,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    module = db.query(ModuleModel).filter(ModuleModel.id_module == id_module).first()
    if not module:
        raise HTTPException(status_code=404, detail="Module introuvable")

    db.delete(module)
    db.commit()
    return {"message": "Module supprimé"}


@app.get("/etudiants")
def read_etudiants(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    return db.query(Etudiant).all()


@app.post("/etudiants")
def create_etudiant(
    payload: EtudiantPayload,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    etudiant = Etudiant(
        nom=payload.nom,
        prenom=payload.prenom,
        id_filiere=payload.id_filiere,
    )
    db.add(etudiant)
    db.commit()
    db.refresh(etudiant)
    return etudiant


@app.put("/etudiants/{id_etudiant}")
def update_etudiant(
    id_etudiant: int,
    payload: EtudiantPayload,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    etudiant = db.query(Etudiant).filter(Etudiant.id_etudiant == id_etudiant).first()
    if not etudiant:
        raise HTTPException(status_code=404, detail="Étudiant introuvable")

    etudiant.nom = payload.nom
    etudiant.prenom = payload.prenom
    etudiant.id_filiere = payload.id_filiere
    db.commit()
    db.refresh(etudiant)
    return etudiant


@app.delete("/etudiants/{id_etudiant}")
def delete_etudiant(
    id_etudiant: int,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    etudiant = db.query(Etudiant).filter(Etudiant.id_etudiant == id_etudiant).first()
    if not etudiant:
        raise HTTPException(status_code=404, detail="Étudiant introuvable")

    db.delete(etudiant)
    db.commit()
    return {"message": "Étudiant supprimé"}


@app.get("/seances")
def read_seances(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    return db.query(Seance).all()


@app.post("/seances")
def create_seance(
    payload: SeancePayload,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    professeur = get_current_professeur(token, db)
    seance = Seance(
        date_seance=parse_iso_date(payload.date_seance),
        heure_debut=parse_iso_time(payload.heure_debut),
        heure_fin=parse_iso_time(payload.heure_fin),
        id_prof=professeur.id_prof,
        id_module=payload.id_module,
        id_filiere=payload.id_filiere,
    )
    db.add(seance)
    db.commit()
    db.refresh(seance)
    return seance


@app.get("/presences")
def read_presences(
    id_seance: int, db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
):
    return db.query(Presence).filter(Presence.id_seance == id_seance).all()


@app.get("/presences/etudiant/{id_etudiant}")
def read_presences_by_etudiant(
    id_etudiant: int,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    return db.query(Presence).filter(Presence.id_etudiant == id_etudiant).all()


@app.get("/presences/stats")
def read_presences_stats(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    presences = db.query(Presence).all()
    filieres = {item.id_filiere: item for item in db.query(Filiere).all()}
    seances = {item.id_seance: item for item in db.query(Seance).all()}
    etudiants = {item.id_etudiant: item for item in db.query(Etudiant).all()}

    by_filiere_map = {}
    absences_map = {}

    for presence in presences:
        seance = seances.get(presence.id_seance)
        if not seance:
            continue

        filiere = filieres.get(seance.id_filiere)
        if not filiere:
            continue

        if filiere.id_filiere not in by_filiere_map:
            by_filiere_map[filiere.id_filiere] = {
                "id_filiere": filiere.id_filiere,
                "nom_filiere": filiere.nom_filiere,
                "present_count": 0,
                "total_records": 0,
            }

        by_filiere_map[filiere.id_filiere]["total_records"] += 1
        if presence.statut == "Present":
            by_filiere_map[filiere.id_filiere]["present_count"] += 1

        if presence.statut == "Absent":
            absences_map[presence.id_etudiant] = (
                absences_map.get(presence.id_etudiant, 0) + 1
            )

    by_filiere = list(by_filiere_map.values())
    by_filiere.sort(key=lambda item: item["nom_filiere"])

    top_absentees = []
    for id_etudiant, absence_count in sorted(
        absences_map.items(), key=lambda item: item[1], reverse=True
    )[:5]:
        etudiant = etudiants.get(id_etudiant)
        if not etudiant:
            continue
        top_absentees.append(
            {
                "id_etudiant": etudiant.id_etudiant,
                "nom": etudiant.nom,
                "prenom": etudiant.prenom,
                "absence_count": absence_count,
            }
        )

    return {"by_filiere": by_filiere, "top_absentees": top_absentees}


@app.post("/presences")
def submit_presences(
    data: PresenceSubmission,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
):
    for record in data.records:
        existing = db.query(Presence).filter(
            Presence.id_seance == data.id_seance,
            Presence.id_etudiant == record.id_etudiant,
        ).first()

        if existing:
            existing.statut = record.statut
            existing.commentaire = record.commentaire
        else:
            db.add(
                Presence(
                    id_seance=data.id_seance,
                    id_etudiant=record.id_etudiant,
                    statut=record.statut,
                    commentaire=record.commentaire,
                )
            )

    db.commit()
    return {"message": "Présences enregistrées"}
