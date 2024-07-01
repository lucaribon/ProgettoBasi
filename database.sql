-- CREAZIONE DATABASE

DROP TABLE IF EXISTS Utente;
DROP TABLE IF EXISTS Recensione;
DROP TABLE IF EXISTS Luogo;
DROP TABLE IF EXISTS Impresa;
DROP TABLE IF EXISTS Privato;
DROP TABLE IF EXISTS Immagine;
DROP TABLE IF EXISTS ImmagineAnnuncio;
DROP TABLE IF EXISTS Annuncio;
DROP TABLE IF EXISTS Preferenze;
DROP TABLE IF EXISTS Prezzo;
DROP TABLE IF EXISTS Motorizzazione;
DROP TABLE IF EXISTS Automobile;
DROP TABLE IF EXISTS Veicolo;

DROP TYPE IF EXISTS TIPOTRAZIONE;
DROP TYPE IF EXISTS TIPOALIMENTAZIONE;
DROP TYPE IF EXISTS TIPOCAMBIO;

CREATE TYPE TIPOTRAZIONE as ENUM ('Anteriore', 'Integrale', 'Posteriore');
CREATE TYPE TIPOALIMENTAZIONE as ENUM ('Benzina', 'Diesel', 'Etanolo', 'Elettrico', 'Elettrico/Benina','Elettrico/Diesel', 'GPL', 'Metano');
CREATE TYPE TIPOCAMBIO as ENUM ('Automatico', 'Manuale', 'Semiautomatico');

CREATE TABLE Utente(
    Email VARCHAR(64) PRIMARY KEY,
    Pass VARCHAR(64) NOT NULL,
    Telefono VARCHAR(10) NOT NULL,
    NumeroAnnunci INT NOT NULL,
    CHECK (NumeroAnnunci >= 0)
);

CREATE TABLE Recensione(
    EmailRecensore VARCHAR(64),
    EmailRecensito VARCHAR(64),
    Valutazione INT NOT NULL,
    Commento VARCHAR(512),
    CHECK(Valutazione >= 0 AND Valutazione <= 10 AND EmailRecensore != EmailRecensito),
    PRIMARY KEY (EmailRecensore, EmailRecensito),
    FOREIGN KEY (EmailRecensore) REFERENCES Utente(Email),
    FOREIGN KEY (EmailRecensito) REFERENCES Utente(Email)
);

CREATE TABLE Luogo(
    Comune VARCHAR(64) NOT NULL,
    CAP VARCHAR(5) NOT NULL,
    Provincia VARCHAR(2) NOT NULL,
    Stato VARCHAR(2) NOT NULL,
    PRIMARY KEY (Comune, CAP)
);

CREATE TABLE Impresa(
    EmailUtente VARCHAR(64) NOT NULL PRIMARY KEY,
    CodicePartitaIva VARCHAR(11) NOT NULL, 
    NomeImpresa VARCHAR(64) NOT NULL,
    SedeComune VARCHAR(64) NOT NULL,
    SedeCAP VARCHAR(5) NOT NULL,
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email),
    FOREIGN KEY (SedeComune, SedeCAP) REFERENCES Luogo(Comune, CAP)
);

CREATE TABLE Privato(
    EmailUtente VARCHAR(64),
    NomeCognome VARCHAR(64),
    DataNascita DATE
)

CREATE TABLE Immagine(
    UrlImmagine VARCHAR(64) NOT NULL PRIMARY KEY,
    IsCopertina BOOLEAN NOT NULL
);

CREATE TABLE ImmagineAnnuncio(
    UrlImmagine VARCHAR(64) NOT NULL,
    IdAnnuncio INT NOT NULL,
    PRIMARY KEY (UrlImmagine, IdAnnuncio),
    FOREIGN KEY (UrlImmagine) REFERENCES Immagine(Url),
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
);

CREATE TABLE Annuncio(
    IdAnnuncio INT PRIMARY KEY,
    Descrizione VARCHAR(256) NOT NULL,
    Prezzo DECIMAL(10, 2) NOT NULL,
    EmailUtente VARCHAR(64) NOT NULL,
    NumeroTelaio VARCHAR(17) NOT NULL,
    CAP VARCHAR(5) NOT NULL,
    Comune VARCHAR(64) NOT NULL,
    Chilometraggio INT,
    AnnoImmatricolazione INT,
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email),
    FOREIGN KEY (NumeroTelaio) REFERENCES Veicolo(NumeroTelaio),
    FOREIGN KEY (CAP, Comune) REFERENCES Luogo(CAP, Comune)
);

CREATE TABLE Preferenze(
    EmailUtente VARCHAR(64) NOT NULL,
    IdAnnuncio INT NOT NULL,
    PRIMARY KEY (EmailUtente, IdAnnuncio),
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email),
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
);

CREATE TABLE Prezzo(
    IdAnnuncio INT NOT NULL,
    DataPrezzo TIMESTAMP NOT NULL,
    Valore DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (IdAnnuncio, DataPrezzo),
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
);

CREATE TABLE Motorizzazione(
    CodiceMotore VARCHAR(64) PRIMARY KEY,
    Alimentazione TIPOALIMENTAZIONE NOT NULL,
    Potenza INT NOT NULL,
    Trazione TIPOTRAZIONE NOT NULL,
    Cilindri INT NOT NULL,
    Cilindrata INT NOT NULL
);

CREATE TABLE Automobile(
    Marca VARCHAR(64) NOT NULL,
    Modello VARCHAR(64) NOT NULL,
    Versione VARCHAR(64) NOT NULL,
    Carrozzeria VARCHAR(64) NOT NULL,
    Cambio TIPOCAMBIO NOT NULL,
    NumPosti INT NOT NULL,
    CodiceMotore VARCHAR(64) NOT NULL,
    ClasseEmissioni VARCHAR(64),
    PRIMARY KEY (Marca, Modello, Versione),
    FOREIGN KEY (CodiceMotore) REFERENCES Motorizzazione(CodiceMotore)
);

CREATE TABLE Veicolo(
    NumeroTelaio VARCHAR(17) PRIMARY KEY,
    Targa VARCHAR(7) NOT NULL,
    Colore VARCHAR(64) NOT NULL,
    MarcaAuto VARCHAR(64) NOT NULL,
    ModelloAuto VARCHAR(64) NOT NULL,
    VersioneAuto VARCHAR(64) NOT NULL,
    FOREIGN KEY (MarcaAuto, ModelloAuto, VersioneAuto) REFERENCES Automobile(Marca, Modello, Versione)
);
-- TRIGGER

-- Controllo immagine di copertina
CREATE OR REPLACE FUNCTION copertinaUnica()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    copertine int;
BEGIN
    SELECT COUNT(*) INTO copertine
    FROM ImmagineAnnuncio as IA JOIN Immagine as I ON IA.UrlImmagine=I.UrlImmagine
    WHERE I.IsCopertina=TRUE AND IA.IdAnnuncio=NEW.IdAnnuncio;
    
    IF copertine>0 THEN
        RAISE EXCEPTION 'Impossibile aggiungere immagine di copertina. Già presente';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER controllaCopertineAnnunci BEFORE INSERT ON ImmagineAnnuncio
FOR EACH ROW
EXECUTE FUNCTION copertinaUnica();

-- Controllo che un annuncio di un veicolo nuovo sia fatto solo da impresa
CREATE OR REPLACE FUNCTION controlloVeicoloNuovo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.AnnoImmatricolazione IS NULL THEN
        IF NOT EXISTS (SELECT * FROM Impresa WHERE EmailUtente=NEW.EmailUtente) THEN
            RAISE EXCEPTION 'Un veicolo nuovo può essere venduto solo da una impresa';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER controlloVeicoloNuovoImpresa BEFORE INSERT ON Annuncio
FOR EACH ROW
EXECUTE FUNCTION controlloVeicoloNuovo();


-- INSERIMENTO DATI


-- 