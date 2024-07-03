-------------------------------------------------------------------------------------------------------
-- SETUP AMBIENTE
-------------------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS MediaRecensioni;

DROP TABLE IF EXISTS Recensione;
DROP TABLE IF EXISTS Preferenze;
DROP TABLE IF EXISTS Impresa;
DROP TABLE IF EXISTS Privato;
DROP TABLE IF EXISTS ImmagineAnnuncio;
DROP TABLE IF EXISTS Prezzo;
DROP TABLE IF EXISTS Annuncio;
DROP TABLE IF EXISTS Utente;
DROP TABLE IF EXISTS Immagine;
DROP TABLE IF EXISTS Luogo;
DROP TABLE IF EXISTS Veicolo;
DROP TABLE IF EXISTS Automobile;
DROP TABLE IF EXISTS Motorizzazione;

DROP TYPE IF EXISTS TIPOTRAZIONE;
DROP TYPE IF EXISTS TIPOALIMENTAZIONE;
DROP TYPE IF EXISTS TIPOCAMBIO;

-------------------------------------------------------------------------------------------------------
-- CREAZIONE TIPI ENUMERATORI
-------------------------------------------------------------------------------------------------------
CREATE TYPE TIPOTRAZIONE as ENUM ('Anteriore', 'Integrale', 'Posteriore');
CREATE TYPE TIPOALIMENTAZIONE as ENUM ('Benzina', 'Diesel', 'Etanolo', 'Elettrico', 'Elettrico/Benzina','Elettrico/Diesel', 'GPL', 'Metano');
CREATE TYPE TIPOCAMBIO as ENUM ('Automatico', 'Manuale', 'Semiautomatico');

-------------------------------------------------------------------------------------------------------
-- CREAZIONE TABELLE
-------------------------------------------------------------------------------------------------------
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
    FOREIGN KEY (EmailRecensore) REFERENCES Utente(Email) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (EmailRecensito) REFERENCES Utente(Email) 
        ON DELETE CASCADE
        ON UPDATE CASCADE
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
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (SedeComune, SedeCAP) REFERENCES Luogo(Comune, CAP) 
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Privato(
    EmailUtente VARCHAR(64) NOT NULL PRIMARY KEY,
    NomeCognome VARCHAR(64) NOT NULL,
    DataNascita DATE,
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email) 
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Immagine(
    UrlImmagine VARCHAR(256) NOT NULL PRIMARY KEY,
    IsCopertina BOOLEAN NOT NULL
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
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Veicolo(
    NumeroTelaio VARCHAR(17) PRIMARY KEY,
    Targa VARCHAR(7) NOT NULL,
    Colore VARCHAR(64) NOT NULL,
    MarcaAuto VARCHAR(64) NOT NULL,
    ModelloAuto VARCHAR(64) NOT NULL,
    VersioneAuto VARCHAR(64) NOT NULL,
    FOREIGN KEY (MarcaAuto, ModelloAuto, VersioneAuto) REFERENCES Automobile(Marca, Modello, Versione)
        ON DELETE CASCADE
        ON UPDATE CASCADE
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
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (NumeroTelaio) REFERENCES Veicolo(NumeroTelaio)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (CAP, Comune) REFERENCES Luogo(CAP, Comune)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE ImmagineAnnuncio(
    UrlImmagine VARCHAR(256) NOT NULL,
    IdAnnuncio INT NOT NULL,
    PRIMARY KEY (UrlImmagine, IdAnnuncio),
    FOREIGN KEY (UrlImmagine) REFERENCES Immagine(UrlImmagine)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Preferenze(
    EmailUtente VARCHAR(64) NOT NULL,
    IdAnnuncio INT NOT NULL,
    PRIMARY KEY (EmailUtente, IdAnnuncio),
    FOREIGN KEY (EmailUtente) REFERENCES Utente(Email)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Prezzo(
    IdAnnuncio INT NOT NULL,
    DataPrezzo TIMESTAMP NOT NULL,
    Valore DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (IdAnnuncio, DataPrezzo),
    FOREIGN KEY (IdAnnuncio) REFERENCES Annuncio(IdAnnuncio)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-------------------------------------------------------------------------------------------------------
-- TRIGGER
-------------------------------------------------------------------------------------------------------
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
    WHERE I.IsCopertina=TRUE AND IA.IdAnnuncio=NEW.IdAnnuncio
    GROUP BY IA.IdAnnuncio;
    
    IF copertine>1 THEN
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

-- incremento numero annunci utente dopo inserimento annuncio
CREATE OR REPLACE FUNCTION incrementaNumeroAnnunci()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Utente
    SET NumeroAnnunci=NumeroAnnunci+1
    WHERE Email=NEW.EmailUtente;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER incrementaNumeroAnnunciUtente AFTER INSERT ON Annuncio
FOR EACH ROW
EXECUTE FUNCTION incrementaNumeroAnnunci();

-- inserisce i nuovi prezzi o gli aggiornamenti dei prezzi nella tabella Prezzo
CREATE OR REPLACE FUNCTION aggiornaTabellaPrezzo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Prezzo(IdAnnuncio, DataPrezzo, Valore)
    VALUES (NEW.IdAnnuncio, CURRENT_TIMESTAMP, NEW.Prezzo);

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER aggiornaStoricoPrezzoAnnuncio AFTER INSERT OR UPDATE ON Annuncio
FOR EACH ROW
EXECUTE FUNCTION aggiornaTabellaPrezzo();
-------------------------------------------------------------------------------------------------------
-- INSERIMENTO DATI
-------------------------------------------------------------------------------------------------------
-- INSERIMENTO LUOGHI
INSERT INTO Luogo(Comune, CAP, Provincia, Stato) VALUES
('Palermo','90126','PA','IT'),
('Padova','35010','PD','IT'),
('Vicenza','36100','VI','IT'),
('Berlin','10176','BE','DE'),
('Roma','00187','RM','IT'),
('Casalserugo','35020','PD','IT');

-- INSERIMENTO UTENTI
INSERT INTO Utente(Email, Pass, Telefono, NumeroAnnunci) VALUES 
('deodatologgia@gmail.com', 'deologgia42', '3367979106', 0), -- privato
('cirorusso@gmail.com','cirorusso','3274482743', 0), -- privato
('guidolavespa@libero.it','guguvespa', '3331247590', 0), -- privato
('marcopolo@tiscali.it','marchetto6', '3245566709', 0), -- privato
('anitatrevisani@autosrl.com','amolemacchine','3983135981', 0), -- impresa
('beppefucile@autoclass.it','occhiobalocchio','3331247590', 0), -- impresa
('lorisgommata@ceccatomotors.it','corrievai', '3245675132', 0), -- impresa
('wolfgang.chan@supercars.de','mynameiswolfgang','9729421589', 0); -- impresa

INSERT INTO Privato(EmailUtente, NomeCognome, DataNascita) VALUES
('deodatologgia@gmail.com','Deodato Loggia', '2000-01-01'),
('cirorusso@gmail.com', 'Ciro Russo', '1979-04-10'),
('guidolavespa@libero.it','Guido La Vespa', '1990-05-15'),
('marcopolo@tiscali.it','Marco Polo', '1985-12-25');

INSERT INTO Impresa(EmailUtente, CodicePartitaIva, NomeImpresa, SedeComune, SedeCAP) VALUES
('anitatrevisani@autosrl.com','12345678901','AutoSRL','Palermo','90126'),
('beppefucile@autoclass.it','98742634145','AutoClass','Padova','35010'),
('lorisgommata@ceccatomotors.it','45678912301','CeccatoMotors','Vicenza','36100'),
('wolfgang.chan@supercars.de','78784723144','SuperCars','Berlin','10176');

-- INSERIMENTO RECENSIONI
INSERT INTO Recensione(EmailRecensore, EmailRecensito, Valutazione, Commento) VALUES
('deodatologgia@gmail.com','anitatrevisani@autosrl.com', 8, 'Ottimo venditore, ottima offerta, macchina in perfette condizioni e personale molto cordiale.'),
('wolfgang.chan@supercars.de','lorisgommata@ceccatomotors.it', 3, 'Als klassischer italienischer Käufer forderte er mich auf, ohne Rechnung zu zahlen, und als ich mich weigerte, geriet er auf dem Parkplatz des Händlers ins Schleudern'),
('anitatrevisani@autosrl.com', 'lorisgommata@ceccatomotors.it', 4, 'Venditore scortese, mi ha mandato via in malo modo perchè aveva appena litigato con la moglie.'),
('cirorusso@gmail.com', 'beppefucile@autoclass.it', 6, 'Buon venditore, macchina in buone condizioni, ma il prezzo era un po'' troppo alto.'),
('anitatrevisani@autosrl.com','beppefucile@autoclass.it', 4, 'La macchina non si accende più, unlucky'),
('lorisgommata@ceccatomotors.it','beppefucile@autoclass.it', 1, 'Ho chiesto di pagare all''italiana, ma il venditore ha rifiutato. Inutile dire che me ne sono andato sgommando per la rabbia.'),
('anitatrevisani@autosrl.com', 'cirorusso@gmail.com', 7, 'Ottimo venditore, macchina in ottime condizioni, prezzo giusto.'),
('guidolavespa@libero.it', 'cirorusso@gmail.com', 10, 'Prezzone, l''auto dei miei sogni, finalmente mia!.'),
('deodatologgia@gmail.com', 'cirorusso@gmail.com', 8, 'Ottima impressione, tornerò a fare affari con lui.'),
('deodatologgia@gmail.com', 'wolfgang.chan@supercars.de', 10, 'Venditore molto professionale, macchina in ottime condizioni, prezzo giusto.'),
('cirorusso@gmail.com', 'wolfgang.chan@supercars.de', 9, 'Venditore estero, molto attento ai dettagli e disposto a venirti incontro.');

-- INSERIMENTO IMMAGINI
INSERT INTO Immagine(UrlImmagine, IsCopertina) VALUES
-- audi a4 2020 business
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-1.jpg', TRUE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-2.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-3.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-4.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-5.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-6.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-7.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-8.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-9.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-10.jpg', FALSE),
-- audi a4 2020 s-line 
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-1.jpg', TRUE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-2.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-3.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-4.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-5.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-6.jpg', FALSE),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-7.jpg', FALSE),
-- toyota yaris 2020
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-1.jpg', TRUE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-2.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-3.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-4.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-5.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-6.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-7.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-8.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-9.jpg', FALSE),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-10.jpg', FALSE), 
-- volkswagen passat 2021
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-1.jpg', TRUE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-2.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-3.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-4.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-5.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-6.jpg', FALSE),
-- skoda octavia 2021
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-1.jpg', TRUE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-2.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-3.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-4.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-5.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-6.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-7.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-8.jpg', FALSE),
-- bmw m3 2010 
('https://www.autosearch.it/img/lorisgommata%40ceccatomotors%2Eit/bmw-m3-2010-1.jpg', TRUE),
-- audi a4 2006 
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-1.jpg', TRUE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-2.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-3.jpg', FALSE),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-4.jpg', FALSE),
-- peugeot 208 2024
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-1.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-2.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-3.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-4.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-5.jpg', TRUE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-6.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-7.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-8.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-9.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-10.jpg', FALSE),
-- opel corsa 2024
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-1.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-2.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-3.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-4.jpg', FALSE),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-5.jpg', FALSE);

-- INSERIMENTO MOTORIZZAZIONI
INSERT INTO Motorizzazione(CodiceMotore, Alimentazione, Potenza, Trazione, Cilindri, Cilindrata) VALUES
('12345678901', 'Benzina', 150, 'Anteriore', 4, 2000),
('98742634145', 'Diesel', 120, 'Anteriore', 4, 1600),
('45678912301', 'Benzina', 500, 'Posteriore', 6, 3000),
('78784723144', 'Benzina', 300, 'Integrale', 8, 4000),
('32356479874', 'Elettrico/Benzina', 110, 'Anteriore', 3, 1200),
('57234918235', 'Benzina', 136, 'Anteriore', 3, 1199);

-- INSERIMENTO AUTO
INSERT INTO Automobile(Marca, Modello, Versione, Carrozzeria, Cambio, NumPosti, CodiceMotore, ClasseEmissioni) VALUES
('Audi', 'A4', '2020 Business', 'Station Wagon', 'Automatico', 5, '12345678901', 'Euro 6'),
('Audi', 'A4', '2020 S-Line', 'Station Wagon', 'Automatico', 5, '12345678901', 'Euro 6'),
('Toyota', 'Yaris', '2020', 'City Car', 'Automatico', 5, '32356479874', 'Euro 6'),
('Volkswagen', 'Passat', '2021', 'Station Wagon', 'Automatico', 5, '78784723144', 'Euro 6'),
('Skoda', 'Octavia', '2021', 'Station Wagon', 'Automatico', 5, '98742634145', 'Euro 6'),
('BMW', 'M3', '2010', 'Berlina', 'Semiautomatico', 4, '45678912301', 'Euro 4'),
('Audi', 'A4', '2006', 'Berlina', 'Manuale', 5, '12345678901', 'Euro 3'),
('Peugeot', '208', '2024', 'City Car', 'Automatico', 5, '57234918235', 'Euro 6'),
('Opel','Corsa','2024', 'City Car', 'Manuale', 5, '57234918235', 'Euro 6');

-- INSERIMENTO VEICOLI
INSERT INTO Veicolo(NumeroTelaio, Targa, Colore, MarcaAuto, ModelloAuto, VersioneAuto) VALUES
('WAUZZZ8KZMA000001', 'AA001AA', 'Nero', 'Audi', 'A4', '2020 Business'),
('WAUZZZ8KZMA040002', 'AA002AA', 'Bianco', 'Audi', 'A4', '2020 S-Line'),
('JTDKTUD3000000001', 'AA003AA', 'Blu', 'Toyota', 'Yaris', '2020'),
('WVWZZZ1JZ3W000000', 'AA000AA', 'Bianco', 'Volkswagen', 'Passat', '2021'),
('TMBJF9NE3M0000001', 'AA004AA', 'Grigio', 'Skoda', 'Octavia', '2021'),
('WBSBL92000EW00001', 'AA005AA', 'Nero', 'BMW', 'M3', '2010'),
('WAUZZZ8E76A000001', 'AA006AA', 'Nero', 'Audi', 'A4', '2006'),
('WVWZZZ1J123A00001', 'AA007AA', 'Giallo', 'Opel', 'Corsa', '2024'),
('WVWZZZ1J178A00001', 'AA008AA', 'Rosso', 'Peugeot', '208', '2024');

-- INSERIMENTO ANNUNCI
INSERT INTO Annuncio(IdAnnuncio, Descrizione, Prezzo, EmailUtente, NumeroTelaio, CAP, Comune, Chilometraggio, AnnoImmatricolazione) VALUES
(1, 'Audi A4 2020 Business', 30000.00, 'cirorusso@gmail.com', 'WAUZZZ8KZMA000001', '90126', 'Palermo', 100000, 2020),
(2, 'Audi A4 2020 S-Line', 47000.00, 'cirorusso@gmail.com', 'WAUZZZ8KZMA040002', '90126', 'Palermo', 120000, 2020),
(3, 'Toyota Yaris 2020', 20000.00, 'anitatrevisani@autosrl.com', 'JTDKTUD3000000001', '35010', 'Padova', 50000, 2020),
(4, 'Volkswagen Passat 2021', 12000.00, 'wolfgang.chan@supercars.de', 'WVWZZZ1JZ3W000000', '10176', 'Berlin', NULL, NULL),
(5, 'Skoda Octavia 2021', 15000.00, 'beppefucile@autoclass.it', 'TMBJF9NE3M0000001', '35010', 'Padova', 50000, 2021),
(6, 'BMW M3 2010', 49000.00, 'lorisgommata@ceccatomotors.it', 'WBSBL92000EW00001', '36100', 'Vicenza', 5000, 2010),
(7, 'Audi A4 2006', 100000.00, 'beppefucile@autoclass.it', 'WAUZZZ8E76A000001', '35010', 'Padova', 500000, 2006),
(8, 'Peugeot 208 2024', 29000.00, 'wolfgang.chan@supercars.de', 'WVWZZZ1J178A00001', '10176', 'Berlin', NULL, NULL),
(9, 'Opel Corsa 2024', 27000.00, 'wolfgang.chan@supercars.de', 'WVWZZZ1J123A00001', '10176', 'Berlin', NULL, NULL);

-- INSERIMENTO IMMAGINI-ANNUNCI
INSERT INTO ImmagineAnnuncio(UrlImmagine, IdAnnuncio) VALUES
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-1.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-2.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-3.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-4.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-5.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-6.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-7.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-8.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-9.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-business-10.jpg', 1),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-1.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-2.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-3.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-4.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-5.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-6.jpg', 2),
('https://www.autosearch.it/img/cirorusso%40gmail%2Ecom/audi-a4-2020-s-line-7.jpg', 2),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-1.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-2.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-3.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-4.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-5.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-6.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-7.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-8.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-9.jpg', 3),
('https://www.autosearch.it/img/anitatrevisani%40autosrl%2Ecom/toyota-yaris-2020-10.jpg', 3),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-1.jpg', 4),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-2.jpg', 4),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-3.jpg', 4),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-4.jpg', 4),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-5.jpg', 4),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/volkswagen-passat-2021-6.jpg', 4),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-1.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-2.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-3.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-4.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-5.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-6.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-7.jpg', 5),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/skoda-octavia-2021-8.jpg', 5),
('https://www.autosearch.it/img/lorisgommata%40ceccatomotors%2Eit/bmw-m3-2010-1.jpg', 6),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-1.jpg', 7),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-2.jpg', 7),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-3.jpg', 7),
('https://www.autosearch.it/img/beppefucile%40autoclass%2Eit/audi-a4-2006-4.jpg', 7),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-1.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-2.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-3.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-4.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-5.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-6.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-7.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-8.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-9.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/peugeot-208-2024-10.jpg', 8),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-1.jpg', 9),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-2.jpg', 9),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-3.jpg', 9),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-4.jpg', 9),
('https://www.autosearch.it/img/wolfgang%2Echan%40supercars%2Ede/opel-corsa-2024-5.jpg', 9);

-- INSERIMENTO PREFERENZE
INSERT INTO Preferenze(EmailUtente, IdAnnuncio) VALUES
('deodatologgia@gmail.com', 6),
('deodatologgia@gmail.com', 7),
('deodatologgia@gmail.com', 2),
('deodatologgia@gmail.com', 4),
('deodatologgia@gmail.com', 9),
('cirorusso@gmail.com', 4),
('cirorusso@gmail.com', 5),
('cirorusso@gmail.com', 6),
('cirorusso@gmail.com', 8),
('cirorusso@gmail.com', 9),
('guidolavespa@libero.it', 1),
('guidolavespa@libero.it', 6),
('guidolavespa@libero.it', 2),
('guidolavespa@libero.it', 3),
('guidolavespa@libero.it', 4),
('guidolavespa@libero.it', 9),
('marcopolo@tiscali.it', 1),
('marcopolo@tiscali.it', 2),
('marcopolo@tiscali.it', 3),
('marcopolo@tiscali.it', 9),
('marcopolo@tiscali.it', 6),
('marcopolo@tiscali.it', 5);

-- INSERIMENTO PREZZI 
INSERT INTO Prezzo(IdAnnuncio, DataPrezzo, Valore) VALUES
(1, '2024-01-01 00:00:00', 35000.00),
(1, '2024-02-05 00:00:00', 37000.00),
(1, '2024-05-08 00:00:00', 32000.00),

(2, '2024-01-04 00:00:00', 35000.00),
(2, '2024-06-20 00:00:00', 45000.00),

(4, '2024-02-24 00:00:00', 13500.00),

(6, '2024-01-02 00:00:00', 52000.00),
(6, '2024-01-06 00:00:00', 50000.00),

(8, '2024-01-01 00:00:00', 27000.00),
(8, '2024-02-05 00:00:00', 30000.00),
(8, '2024-05-08 00:00:00', 28000.00),

(9, '2024-01-01 00:00:00', 25000.00),
(9, '2024-02-05 00:00:00', 28000.00),
(9, '2024-05-08 00:00:00', 26000.00);

-------------------------------------------------------------------------------------------------------
-- QUERY
-------------------------------------------------------------------------------------------------------
-- contare il numero di annunci per ogni utente
SELECT Email, COUNT(NumeroAnnunci) AS AnnunciPubblicati
FROM Utente AS U JOIN Annuncio AS A ON U.Email=A.EmailUtente
GROUP BY Email;

-- elencare gli annunci di veicoli a trazione anteriore
SELECT IdAnnuncio, Descrizione, Colore, Prezzo, Chilometraggio, AnnoImmatricolazione, Comune, CAP, EmailUtente
FROM Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio 
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
    JOIN Motorizzazione AS M ON AU.CodiceMotore=M.CodiceMotore
WHERE M.Trazione='Anteriore';

-- prezzo medio dei veicoli per ogni marca in ogni comune italiano
SELECT L.Comune, AU.Marca, TRUNC(AVG(A.Prezzo)) AS PrezzoMedio
FROM Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio 
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
    JOIN Luogo AS L ON A.CAP=L.CAP AND A.Comune=L.Comune
GROUP BY L.Comune, L.Stato, AU.Marca
HAVING L.Stato='IT';

-- trovare le alimentazioni più comuni tra gli annunci degli utenti con valutazione media di recensioni superiori alla media
CREATE VIEW MediaRecensioni AS
SELECT R.EmailRecensito AS UtenteRecensito, AVG(R.Valutazione) as MediaValutazione
FROM Recensione AS R 
GROUP BY R.EmailRecensito;

SELECT A.EmailUtente, M.Alimentazione, COUNT(*) AS AnnunciAlimentazione
FROM Annuncio as A JOIN Veicolo as V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile as AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
    JOIN Motorizzazione as M ON AU.CodiceMotore=M.CodiceMotore
    JOIN MediaRecensioni as MR ON A.EmailUtente=MR.UtenteRecensito
WHERE MR.MediaValutazione > (
    SELECT AVG(MediaValutazione) as MediaGlobale
    FROM MediaRecensioni
)
GROUP BY A.EmailUtente, M.Alimentazione
ORDER BY AnnunciAlimentazione DESC;

-- trovare la marca di auto salvata da più di un utente come preferita, ordinando per numero di preferenze
SELECT AU.Marca, COUNT(*) AS Preferenze
FROM Preferenze AS P JOIN Annuncio AS A ON P.IdAnnuncio=A.IdAnnuncio
    JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
GROUP BY AU.Marca
HAVING COUNT(*) > 1
ORDER BY Preferenze DESC;

-- stampare i nomi di chi ha fatto modifiche al prezzo di un annuncio nell'ultimo mese, i dati relativi al prezzo modificato e i dati dell'annuncio
SELECT I.NomeImpresa AS Nome, A.IdAnnuncio, DATE(P.DataPrezzo) AS DataModifica, P.Valore AS PrezzoModificato, AU.Marca, AU.Modello, AU.Versione
FROM Annuncio AS A JOIN Impresa AS I ON A.EmailUtente=I.EmailUtente
    JOIN Prezzo AS P ON A.IdAnnuncio=P.IdAnnuncio
    JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
WHERE P.DataPrezzo >= CURRENT_DATE - 30

UNION ALL

SELECT Pri.NomeCognome AS Nome, A.IdAnnuncio, DATE(P.DataPrezzo) AS DataModifica, P.Valore AS PrezzoModificato, AU.Marca, AU.Modello, AU.Versione
FROM Annuncio AS A JOIN Privato AS Pri ON A.EmailUtente=Pri.EmailUtente
    JOIN Prezzo AS P ON A.IdAnnuncio=P.IdAnnuncio
    JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
WHERE P.DataPrezzo >= CURRENT_DATE - 30
ORDER BY Nome, DataModifica;


-------------------------------------------------------------------------------------------------------
-- QUERY PARAMETRICHE
-------------------------------------------------------------------------------------------------------
-- trovare gli annunci di veicoli con un prezzo nel range specificato
SELECT *
FROM Annuncio as A               
WHERE Prezzo > :prezzoMin AND Prezzo < :prezzoMax;

-- trovare gli annunci localizzati in un comune specifico, di un tipo di utente (privato o impresa) 
SELECT *
FROM Annuncio as A JOIN :tipoUtente as T ON A.EmailUtente=T.EmailUtente
WHERE A.Comune = :comune AND A.CAP = :cap;

-- tutti gli annuncio di un privato che ha media valutazioni superiori a quella specificata
DROP VIEW IF EXISTS MediaRecensioni;
CREATE VIEW MediaRecensioni AS
SELECT R.EmailRecensito AS UtenteRecensito, AVG(R.Valutazione) as MediaValutazione
FROM Recensione AS R 
GROUP BY R.EmailRecensito;

SELECT * 
FROM Annuncio AS A JOIN Privato AS T ON A.EmailUtente=T.EmailUtente
    JOIN MediaRecensioni as R ON A.EmailUtente=R.EmailRecensito
WHERE R.MediaValutazione > :valutazione;

-- visualizza le email degli utenti, e l'auto, che hanno salvato almeno un annuncio come preferito che soddifa i parametri specificati
SELECT P.EmailUtente, AU.Marca, AU.Modello, AU.Versione
FROM Preferenze AS P JOIN Annuncio AS A ON P.IdAnnuncio=A.IdAnnuncio
    JOIN Utente AS U ON P.EmailUtente=U.Email
    JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
    JOIN Motorizzazione AS M ON AU.CodiceMotore=M.CodiceMotore
WHERE M.Trazione = :trazione AND M.Alimentazione = :alimentazione AND M.Potenza > :potenza AND AU.Cambio = :cambio AND AU.NumPosti = :numPosti;

-- reperire suggerimenti di completamento nella barra di ricerca degli annunci
SELECT SELECT A.IdAnnuncio, A.Descrizione, A.Colore, A.Prezzo, A.Chilometraggio, A.AnnoImmatricolazione, A.Comune, A.CAP, A.EmailUtente
FROM Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio
    JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione
WHERE Marca LIKE "%:input%" OR Modello LIKE "%:input%" OR Versione LIKE "%:input%"; 

-- Extra 1:
-- SELECT * FROM *
-- Extra 2:
-- SELECT * FROM * GROUP BY * HAVING *
