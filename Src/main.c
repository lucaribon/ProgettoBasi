#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "./dependencies/lib/libpq-fe.h"

char PG_USER[20] = "admin";
char PG_PASS[20] = "admin";
char PG_DATABASE[30] = "ProgettoBasi";
char PG_HOST[20] = "127.0.0.1";
int PG_PORT = 5432;
PGconn *conn;

// Inizializza la connessione al database
int inizializzaConnessione(char user[], char pass[], char database[], char host[], int port) {
    // Connessione al database
    char infoconn[300];
    sprintf(infoconn, "user=%s password=%s dbname=%s hostaddr=%s port=%d", user, pass, database,
            host, port);
    conn = PQconnectdb(infoconn);

    // Controllo connessione
    if (PQstatus(conn) != CONNECTION_OK) {
        fprintf(stderr, "Connessione al database fallita: %s", PQerrorMessage(conn));
        PQfinish(conn);
        return 1;
    } else {
        return 0;
    }
}

void chiudiConnessione() {
    PQfinish(conn);
    printf("Connessione al database chiusa\n");
}

void stampaRisultato(PGresult *res) {
    int n_tuple = PQntuples(res);
    int n_col = PQnfields(res);

    // nomi colonne
    for (int i = 0; i < n_col; i++) {
        printf(" %-29s ", PQfname(res, i));
    }
    // trattini
    printf("\n");
    for (int i = 0; i < n_col * 29; i = i + 1) {
        printf("%s", "-");
    }
    printf("\n");
    // dati
    for (int i = 0; i < n_tuple; i++) {
        for (int j = 0; j < n_col; j++) {
            printf(" %-29s ", PQgetvalue(res, i, j));
        }
        printf("\n");
    }
}

void eseguiQuery(char query[]) {
    PGresult *res = PQexec(conn, query);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        fprintf(stderr, "Query fallita con errore : \n\t%s", PQerrorMessage(conn));
        PQclear(res);
        return;
    }
    stampaRisultato(res);
    PQclear(res);
}

void eseguiQueryParametrica(char name[], int n_param, const char *const *param) {
    PGresult *res = PQexecPrepared(conn, name, n_param, param, NULL, 0, 0);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        fprintf(stderr, "Query fallita con errore : \n\t%s", PQerrorMessage(conn));
        PQclear(res);
        return;
    }
    stampaRisultato(res);
    PQclear(res);
}

void aspettaTasto() {
    printf("\nPremi un tasto per continuare...");
    getchar();
    getchar();
    system("clear");
}

int main(int argc, char const *argv[]) {
    // Credenziali database

    while (1) {
        printf(
            "    _         _       ____                      _     \n"
            "   / \\  _   _| |_ ___/ ___|  ___  __ _ _ __ ___| |__  \n"
            "  / _ \\| | | | __/ _ \\___ \\ / _ \\/ _` | '__/ __| '_ \\ \n"
            " / ___ \\ |_| | || (_) |__) |  __/ (_| | | | (__| | | |\n"
            "/_/   \\_\\__,_|\\__\\___/____/ \\___|\\__,_|_|  \\___|_| |_|\n"
            "\n");

        // Connessione al database
        int status_db = inizializzaConnessione(PG_USER, PG_PASS, PG_DATABASE, PG_HOST, PG_PORT);
        char status[20];
        if (status_db == 0) {
            sprintf(status, "Connesso");
        } else {
            sprintf(status, "Non connesso");
        }
        printf("---------------------------------\n");
        printf("| STATO DATABASE: %s\t|\n", status);
        printf("---------------------------------\n\n");
        printf("- MODIFICA IMPOSTAZIONI DATABASE\n");
        printf("\t1. Modifica credenziali\n");
        //---------------------------------
        printf("\n- QUERY STATICHE\n");
        printf("\t2. Conta il numero annunci per ogni utente\n");
        printf("\t3. Elencare il numero di veicoli a trazione anteriore\n");
        printf(
            "\t4. Elencare il prezzo medio dei veicoli per ogni marca in ogni comune italiano\n");
        printf(
            "\t5. Elencare le alimentazioni più comuni tra gli annunci degli utenti con "
            "valutazione superiore alla media\n");
        printf(
            "\t6. Trovare la marca di auto salvata da piu' di un utente come preferita, ordinando "
            "per numero di preferenze\n");
        printf(
            "\t7. Elenacare i nomi di chi ha fatto modifiche al prezzo di un annuncio nell'ultimo "
            "mese, i dati relativi al prezzo modificato e i dati dell'annuncio\n");
        //---------------------------------
        printf("\n- QUERY PARAMETRICHE\n");
        printf("\t8. Trovare gli annunci di veicoli con un prezzo nel range specificato\n");
        printf("\t9. Trovare gli annunci localizzati in un comune specifico\n");
        printf(
            "\t10. Tutti gli annunci di un privato che ha media valutazioni superiore a quella "
            "specificata\n");
        printf(
            "\t11. Visualizza le email degli utenti, e l'auto, che hanno salvato almeno un "
            "annuncio come preferito che soddifa i parametri specificati\n");
        printf(
            "\t12. Reperire suggerimenti di completamento nella barra di ricerca degli annunci\n");
        //---------------------------------
        printf("\n- QUERY EXTRA PERSONALIZZATE\n");
        printf("\t13. SELECT ___ FROM ___\n");
        printf("\t14. SELECT ___ FROM ___ WHERE ___ GROUP BY ___ HAVING ___ \n");
        printf("\n---------------------------------\n");
        printf("\t0. Esci\n");

        int scelta;
        printf("> ");
        scanf("%d", &scelta);

        system("clear");

        switch (scelta) {
            case 0:
                chiudiConnessione(conn);
                printf("Grazie, Arrivederci!\n");
                return 0;
            case 1:
                printf("Le credenziali attuali sono: \n");
                printf("- User: %s\n", PG_USER);
                printf("- Password: %s\n", PG_PASS);
                printf("- Database: %s\n", PG_DATABASE);
                printf("- Host: %s\n", PG_HOST);
                printf("- Port: %d\n", PG_PORT);
                printf("\nVuoi modificare le credenziali? (s/n) ");

                char risposta;
                scanf(" %c", &risposta);
                if (risposta != 's' && risposta != 'S') {
                    system("clear");
                    break;
                }
                printf("\nInserisci le nuove credenziali: \n");
                printf("- User: ");
                scanf("%s", &PG_USER[0]);
                printf("- Password: ");
                scanf("%s", &PG_PASS[0]);
                printf("- Database: ");
                scanf("%s", &PG_DATABASE[0]);
                printf("- Host: ");
                scanf("%s", &PG_HOST[0]);
                printf("- Port: ");
                scanf("%d", &PG_PORT);
                break;
            case 2:
                // Query1: contare il numero di annunci per ogni utente
                char query1[] =
                    "SELECT Email, COUNT(NumeroAnnunci) AS AnnunciPubblicati FROM Utente AS U JOIN "
                    "Annuncio AS A ON U.Email=A.EmailUtente GROUP BY Email;";
                eseguiQuery(query1);
                aspettaTasto();
                break;
            case 3:
                // Query2: elencare gli annunci di veicoli a trazione anteriore
                char query2[] =
                    "SELECT IdAnnuncio, Descrizione, Colore, Prezzo, Chilometraggio, "
                    "AnnoImmatricolazione, Comune, CAP, EmailUtente FROM Annuncio AS A JOIN "
                    "Veicolo "
                    "AS V ON A.NumeroTelaio = V.NumeroTelaio JOIN Automobile AS AU ON V.MarcaAuto "
                    "= AU.Marca AND V.ModelloAuto = AU.Modello AND V.VersioneAuto = AU.Versione "
                    "JOIN Motorizzazione AS M ON AU.CodiceMotore = M.CodiceMotore WHERE M.Trazione "
                    "= 'Anteriore' ";
                eseguiQuery(query2);
                aspettaTasto();
                break;
            case 4:
                // Query3: elencare il prezzo medio dei veicoli per ogni marca in ogni comune
                // italiano
                char query3[] =
                    "SELECT L.Comune, AU.Marca,TRUNC(AVG(A.Prezzo)) AS PrezzoMedio FROM Annuncio "
                    "AS A JOIN Veicolo AS V ON A.NumeroTelaio = V.NumeroTelaio JOIN Automobile AS "
                    "AU ON V.MarcaAuto = AU.Marca AND V.ModelloAuto = AU.Modello AND "
                    "V.VersioneAuto = AU.Versione JOIN Luogo AS L ON A.CAP = L.CAP AND A.Comune = "
                    "L.Comune GROUP BY L.Comune, L.Stato, AU.Marca HAVING L.Stato = 'IT' ";
                eseguiQuery(query3);
                aspettaTasto();
                break;
            case 5:
                // Query4: trovare le alimentazioni piu' comuni tra gli annunci degli utenti con
                // valutazione media di recensioni superiori alla media
                char query4[] =
                    "DROP VIEW IF EXISTS MediaRecensioni;"
                    "CREATE VIEW MediaRecensioni AS SELECT R.EmailRecensito AS UtenteRecensito, "
                    "AVG(R.Valutazione) as MediaValutazione FROM Recensione AS R GROUP BY "
                    "R.EmailRecensito;SELECT A.EmailUtente, M.Alimentazione, COUNT(*) AS "
                    "AnnunciAlimentazione FROM Annuncio as A JOIN Veicolo as V ON "
                    "A.NumeroTelaio=V.NumeroTelaio JOIN Automobile as AU ON V.MarcaAuto=AU.Marca "
                    "AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione JOIN "
                    "Motorizzazione as M ON AU.CodiceMotore=M.CodiceMotore JOIN MediaRecensioni as "
                    "MR ON A.EmailUtente=MR.UtenteRecensito WHERE MR.MediaValutazione > (SELECT "
                    "AVG(MediaValutazione) as MediaGlobale FROM MediaRecensioni) GROUP BY "
                    "A.EmailUtente, M.Alimentazione ORDER BY AnnunciAlimentazione DESC;";
                eseguiQuery(query4);
                aspettaTasto();
                break;
            case 6:
                // trovare la marca di auto salvata da piu' di un utente come preferita, ordinando
                // per numero di preferenze
                char query5[] =
                    "SELECT AU.Marca, COUNT(*) AS Preferenze FROM Preferenze AS P JOIN Annuncio AS "
                    "A ON P.IdAnnuncio=A.IdAnnuncio JOIN Veicolo AS V ON "
                    "A.NumeroTelaio=V.NumeroTelaio JOIN Automobile AS AU ON V.MarcaAuto=AU.Marca "
                    "AND V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione GROUP BY AU.Marca "
                    "HAVING COUNT(*) > 1 ORDER BY Preferenze DESC;";
                eseguiQuery(query5);
                aspettaTasto();
                break;
            case 7:
                // stampare i nomi di chi ha fatto modifiche al prezzo di un annuncio nell'ultimo
                // mese, i dati relativi al prezzo modificato e i dati dell'annuncio
                char query6[] =
                    "SELECT I.NomeImpresa AS Nome, A.IdAnnuncio, DATE(P.DataPrezzo) AS "
                    "DataModifica, P.Valore AS PrezzoModificato, AU.Marca, AU.Modello, AU.Versione "
                    "FROM Annuncio AS A JOIN Impresa AS I ON A.EmailUtente=I.EmailUtente JOIN "
                    "Prezzo AS P ON A.IdAnnuncio=P.IdAnnuncio JOIN Veicolo AS V ON A.NumeroTelaio "
                    "= V.NumeroTelaio JOIN Automobile AS AU ON V.MarcaAuto = AU.Marca AND "
                    "V.ModelloAuto = AU.Modello AND V.VersioneAuto = AU.Versione WHERE "
                    "P.DataPrezzo >= CURRENT_DATE - 30 UNION ALL SELECT Pri.NomeCognome AS Nome, "
                    "A.IdAnnuncio, DATE(P.DataPrezzo) AS DataModifica, P.Valore AS "
                    "PrezzoModificato, "
                    "AU.Marca, AU.Modello,AU.Versione FROM Annuncio AS A JOIN Privato AS Pri ON "
                    "A.EmailUtente =Pri.EmailUtente JOIN Prezzo AS P ON A.IdAnnuncio =P.IdAnnuncio "
                    "JOIN Veicolo AS V ON A.NumeroTelaio =V.NumeroTelaio JOIN Automobile AS AU ON "
                    "V.MarcaAuto =AU.Marca AND V.ModelloAuto = AU.Modello AND V.VersioneAuto "
                    "=AU.Versione WHERE P.DataPrezzo >=CURRENT_DATE - 30 ORDER BY Nome, "
                    "DataModifica;";
                eseguiQuery(query6);
                aspettaTasto();
                break;
            case 8:
                do {
                    system("clear");
                    printf("Query parametrica 1\n");
                    printf("SELECT *\nFROM Annuncio\nWHERE Prezzo >= ___ AND Prezzo <= ___\n\n");

                    printf("Inserisci il prezzo minimo: ");
                    char param1[20];
                    scanf("%s", &param1[0]);
                    printf("Inserisci il prezzo massimo: ");
                    char param2[20];
                    scanf("%s", &param2[0]);

                    printf("\nRisultato query:\n");
                    printf("SELECT *\nFROM Annuncio\nWHERE Prezzo >= %s AND Prezzo <= %s\n", param1,
                           param2);

                    PGresult *statement1 = PQprepare(conn, "queryP1",
                                                     "SELECT * FROM Annuncio WHERE Prezzo >= "
                                                     "$1::decimal AND Prezzo <= $2::decimal",
                                                     2, NULL);
                    const char *const punt[] = {param1, param2};
                    eseguiQueryParametrica("queryP1", 2, punt);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 9:
                do {
                    system("clear");
                    printf("Query parametrica 2\n");
                    printf(
                        "SELECT *\nFROM Annuncio as A \n\tJOIN Impresa as T ON "
                        "A.EmailUtente=T.EmailUtente\nWHERE A.Comune = ____ AND A.CAP = "
                        "_____;\n\n");

                    printf("Inserisci nome del comune: ");
                    char param1[20];
                    scanf("%s", &param1[0]);
                    printf("Inserisci il CAP del comune: ");
                    char param2[20];
                    scanf("%s", &param2[0]);

                    printf("\nRisultato query:\n");
                    printf(
                        "SELECT *\nFROM Annuncio as A \n\tJOIN Impresa as T ON "
                        "A.EmailUtente=T.EmailUtente\nWHERE A.Comune = %s AND A.CAP = %s;\n",
                        param1, param2);

                    PGresult *statement2 =
                        PQprepare(conn, "queryP2",
                                  "SELECT * FROM Annuncio AS A JOIN Impresa AS T ON "
                                  "A.EmailUtente=T.EmailUtente "
                                  "WHERE A.Comune = $1::varchar AND A.CAP = $2::varchar",
                                  2, NULL);
                    const char *const punt[] = {param1, param2};

                    eseguiQueryParametrica("queryP2", 2, punt);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 10:
                do {
                    system("clear");
                    printf("Query parametrica 3\n");
                    printf(
                        "SELECT A.*, R.MediaValutazione\nFROM Annuncio AS A \n\tJOIN Privato AS T "
                        "ON "
                        "A.EmailUtente=T.EmailUtente \n\tJOIN MediaRecensioni as R ON "
                        "A.EmailUtente=R.EmailRecensito \nWHERE R.MediaValutazione > ____; "
                        "\n\n");

                    printf("Inserisci media delle valutazioni: ");
                    char param1[20];
                    scanf("%s", &param1[0]);

                    printf("\nRisultato query:\n");
                    printf(
                        "SELECT A.*, R.MediaValutazione\nFROM \nAnnuncio AS A \n\tJOIN Privato AS "
                        "T ON "
                        "A.EmailUtente=T.EmailUtente \n\tJOIN MediaRecensioni as R ON "
                        "A.EmailUtente=R.UtenteRecensito \nWHERE R.MediaValutazione > %s; "
                        "\n\n",
                        param1);

                    PGresult *creaView =
                        PQexec(conn,
                               "CREATE OR REPLACE VIEW MediaRecensioni AS "
                               "SELECT R.EmailRecensito AS UtenteRecensito, AVG(R.Valutazione) as "
                               "MediaValutazione FROM Recensione AS R GROUP BY R.EmailRecensito; ");

                    PGresult *statement3 = PQprepare(
                        conn, "queryP3",
                        "SELECT A.*, R.MediaValutazione "
                        "FROM Annuncio AS A JOIN Privato AS T ON A.EmailUtente=T.EmailUtente JOIN "
                        "MediaRecensioni as R ON "
                        "A.EmailUtente=R.UtenteRecensito WHERE R.MediaValutazione > $1::decimal;",
                        1, NULL);
                    const char *const punt[] = {param1};

                    eseguiQueryParametrica("queryP3", 1, punt);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 11:
                do {
                    system("clear");
                    printf("Query parametrica 3\n");
                    printf(
                        "SELECT P.EmailUtente, AU.Marca, AU.Modello, AU.Versione\nFROM Preferenze "
                        "AS P\n\tJOIN Annuncio AS A ON P.IdAnnuncio=A.IdAnnuncio\n\tJOIN Utente AS "
                        "U ON "
                        "P.EmailUtente=U.Email\n\tJOIN Veicolo AS V ON "
                        "A.NumeroTelaio=V.NumeroTelaio "
                        "\n\tJOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND "
                        "V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione\n\tJOIN "
                        "Motorizzazione AS M ON AU.CodiceMotore=M.CodiceMotore \nWHERE M.Trazione "
                        "= "
                        "_____ AND M.Alimentazione = ____ AND M.Potenza > ____ "
                        "AND AU.Cambio = ____ AND AU.NumPosti = ____;"
                        "\n\n");

                    printf("Inserisci tipo di trazione (Anteriore, Posteriore, Integrale): ");
                    char param1[20];
                    scanf("%s", &param1[0]);
                    printf(
                        "Inserisci tipo di alimentazione (Benzina, Diesel, Elettrico/Benzina ...) "
                        ": ");
                    char param2[20];
                    scanf("%s", &param2[0]);
                    printf("Inserisci la potenza : ");
                    char param3[20];
                    scanf("%s", &param3[0]);
                    printf("Inserisci tipo di cambio (Automatico, Manuale, Semiautomatico) : ");
                    char param4[20];
                    scanf("%s", &param4[0]);
                    printf("Inserisci numero posti : ");
                    char param5[20];
                    scanf("%s", &param5[0]);

                    printf("\nRisultato query:\n");
                    printf(
                        "SELECT P.EmailUtente, AU.Marca, AU.Modello, AU.Versione\nFROM Preferenze "
                        "AS P\n\tJOIN Annuncio AS A ON P.IdAnnuncio=A.IdAnnuncio\n\tJOIN Utente AS "
                        "U ON "
                        "P.EmailUtente=U.Email\n\tJOIN Veicolo AS V ON "
                        "A.NumeroTelaio=V.NumeroTelaio "
                        "\n\tJOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND "
                        "V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione\n\tJOIN "
                        "Motorizzazione AS M ON AU.CodiceMotore=M.CodiceMotore \nWHERE M.Trazione "
                        "= "
                        "%s AND M.Alimentazione = %s AND M.Potenza > %s "
                        "AND AU.Cambio = %s AND AU.NumPosti = %s;"
                        "\n\n",
                        param1, param2, param3, param4, param5);

                    PGresult *statement4 = PQprepare(
                        conn, "queryP4",
                        "SELECT P.EmailUtente, AU.Marca, AU.Modello, AU.Versione\nFROM Preferenze "
                        "AS P\n\tJOIN Annuncio AS A ON P.IdAnnuncio=A.IdAnnuncio\n\tJOIN Utente AS "
                        "U ON "
                        "P.EmailUtente=U.Email\n\tJOIN Veicolo AS V ON "
                        "A.NumeroTelaio=V.NumeroTelaio "
                        "\n\tJOIN Automobile AS AU ON V.MarcaAuto=AU.Marca AND "
                        "V.ModelloAuto=AU.Modello AND V.VersioneAuto=AU.Versione\n\tJOIN "
                        "Motorizzazione AS M ON AU.CodiceMotore=M.CodiceMotore \nWHERE M.Trazione "
                        "= $1 AND M.Alimentazione = $2 AND M.Potenza > $3 "
                        "AND AU.Cambio = $4 AND AU.NumPosti = $5;",
                        5, NULL);
                    const char *const punt[] = {param1, param2, param3, param4, param5};

                    eseguiQueryParametrica("queryP4", 5, punt);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 12:
                do {
                    system("clear");
                    printf("Query parametrica 3\n");
                    printf(
                        "SELECT A.IdAnnuncio, A.Descrizione, V.Colore, A.Prezzo, "
                        "A.Chilometraggio, A.AnnoImmatricolazione, A.Comune, A.CAP, A.EmailUtente\n"
                        "FROM "
                        "Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio\n\tJOIN "
                        "Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND "
                        "V.VersioneAuto=AU.Versione\nWHERE Marca LIKE '\%____\%' OR Modello LIKE "
                        "'\%____\%' "
                        "OR "
                        "Versione LIKE '\%____\%';\n\n");

                    printf("Inserisci la marca o modello o versione dell'auto: ");
                    char param1[30];
                    scanf("%s", &param1[0]);
                    char input[30] = "";
                    strcat(input, "%");
                    strcat(input, param1);
                    strcat(input, "%");

                    printf("\nRisultato query:\n");
                    printf(
                        "SELECT A.IdAnnuncio, A.Descrizione, V.Colore, A.Prezzo, "
                        "A.Chilometraggio, A.AnnoImmatricolazione, A.Comune, A.CAP, A.EmailUtente\n"
                        "FROM "
                        "Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio\n\tJOIN "
                        "Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND "
                        "V.VersioneAuto=AU.Versione\nWHERE Marca LIKE '%s' OR Modello LIKE "
                        "'%s' "
                        "OR Versione LIKE '%s';\n\n",
                        input, input, input);

                    PGresult *statement5 = PQprepare(
                        conn, "queryP5",
                        "SELECT A.IdAnnuncio, A.Descrizione, V.Colore, A.Prezzo, "
                        "A.Chilometraggio, A.AnnoImmatricolazione, A.Comune, A.CAP, A.EmailUtente "
                        "FROM "
                        "Annuncio AS A JOIN Veicolo AS V ON A.NumeroTelaio=V.NumeroTelaio JOIN "
                        "Automobile AS AU ON V.MarcaAuto=AU.Marca AND V.ModelloAuto=AU.Modello AND "
                        "V.VersioneAuto=AU.Versione WHERE Marca LIKE $1::varchar OR Modello "
                        "LIKE $1::varchar OR Versione LIKE $1::varchar;",
                        1, NULL);
                    const char *const punt[] = {input};

                    eseguiQueryParametrica("queryP5", 1, punt);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 13:
                do {
                    system("clear");
                    printf("Query parametrica 1\n");
                    printf("SELECT ____\nFROM ____\n\n");

                    printf("Inserisci primo parametro: ");
                    char param1[20];
                    scanf("%s", &param1[0]);
                    printf("Inserisci secondo parametro: ");
                    char param2[20];
                    scanf("%s", &param2[0]);

                    printf("\nRisultato query:\n");
                    printf("SELECT %s\nFROM %s\n", param1, param2);

                    char query7[300];
                    sprintf(query7, "SELECT %s FROM %s", param1, param2);

                    eseguiQuery(query7);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            case 14:
                do {
                    system("clear");
                    printf("Query parametrica 2\n");
                    printf("SELECT ____\nFROM ____\nGROUP BY ____\nHAVING ____\n\n");

                    printf("Inserisci primo parametro (SELECT): ");
                    char param1[20];
                    scanf("%s", &param1[0]);
                    printf("Inserisci secondo parametro (FROM): ");
                    char param2[20];
                    scanf("%s", &param2[0]);
                    printf("Inserisci terzo parametro (GROUP BY): ");
                    char param3[20];
                    scanf("%s", &param3[0]);
                    printf("Inserisci quarto parametro (HAVING): ");
                    char param4[20];
                    scanf("%s", &param4[0]);

                    printf("\nRisultato query:\n");
                    printf("SELECT %s\nFROM %s\nGROUP BY %s\nHAVING %s\n", param1, param2, param3,
                           param4);

                    char query7[300];
                    sprintf(query7, "SELECT %s FROM %s", param1, param2);

                    eseguiQuery(query7);
                    printf("\n\nVuoi riprovare? (s/n) ");
                    getchar();
                } while (getchar() == 's');
                break;
            default:
                break;
        }
    }
}