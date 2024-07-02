#include <stdio.h>
#include <stdlib.h>

#include "./dependencies/lib/libpq-fe.h"

// Inizializza la connessione al database
int inizializzaConnessione(PGconn *conn, char user[], char pass[],
                           char database[], char host[], int port) {
    // Connessione al database
    char infoconn[300];
    sprintf(infoconn, "user=%s password=%s dbname=%s hostaddr=%s port=%d", user,
            pass, database, host, port);
    conn = PQconnectdb(infoconn);

    // Controllo connessione
    if (PQstatus(conn) != CONNECTION_OK) {
        fprintf(stderr, "Connessione al database fallita: %s",
                PQerrorMessage(conn));
        PQfinish(conn);
        return 1;
    } else {
        printf("Connessione al database riuscita\n");
        return 0;
    }
}

void chiudiConnessione(PGconn *conn) {
    PQfinish(conn);
    printf("Connessione al database chiusa\n");
}

void stampaRisultato(PGresult *res) {
    int n_tuple = PQntuples(res);
    int n_col = PQnfields(res);

    for (int i = 0; i < n_col; i++) {
        printf("%s\t", PQfname(res, i));
    }
    printf("\n");
    for (int i = 0; i < n_tuple; i++) {
        for (int j = 0; j < n_col; j++) {
            printf("%s\t", PQgetvalue(res, i, j));
        }
        printf("\n");
    }
}

void eseguiQuery(PGconn *conn, char query[]) {
    PGresult *res = PQexec(conn, query);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        fprintf(stderr, "Query fallita con errore : \n\t%s",
                PQerrorMessage(conn));
        PQclear(res);
        return;
    }
    stampaRisultato(res);
    PQclear(res);
}

void eseguiQueryParametrica(PGconn *conn, char query[], int n_param,
                            const char *const *param) {
    PGresult *res =
        PQexecParams(conn, query, n_param, NULL, param, NULL, NULL, 0);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        fprintf(stderr, "Query fallita con errore : \n\t%s",
                PQerrorMessage(conn));
        PQclear(res);
        return;
    }
    stampaRisultato(res);
    PQclear(res);
}

int main(int argc, char const *argv[]) {
    // Credenziali database
    char PG_USER[20] = "postgres";
    char PG_PASS[20] = "postgres";
    char PG_DATABASE[30] = "ProgettoBasi";
    char PG_HOST[20] = "127.0.0.1";
    int PG_PORT = 5432;

    // Connessione al database
    PGconn *conn;
    int status_db = inizializzaConnessione(conn, PG_USER, PG_PASS, PG_DATABASE,
                                           PG_HOST, PG_PORT);
    char status[20];
    if (status_db == 0) {
        sprintf(status, "Connesso");
    } else {
        sprintf(status, "Non connesso");
    }

    while (1) {
        printf(
            "    _         _       ____                      _     \n"
            "   / \\  _   _| |_ ___/ ___|  ___  __ _ _ __ ___| |__  \n"
            "  / _ \\| | | | __/ _ \\___ \\ / _ \\/ _` | '__/ __| '_ \\ \n"
            " / ___ \\ |_| | || (_) |__) |  __/ (_| | | | (__| | | |\n"
            "/_/   \\_\\__,_|\\__\\___/____/ \\___|\\__,_|_|  \\___|_| |_|\n"
            "\n");
        printf("---------------------------------\n");
        printf("| STATO DATABASE: %s\t|\n", status);
        printf("---------------------------------\n\n");
        printf("- MODIFICA IMPOSTAZIONI DATABASE\n");
        printf("\t1. Modifica credenziali\n");
        printf("\n- QUERY STATICHE\n");
        printf("\t2. \n");
        printf("\t3. \n");
        printf("\t4. \n");
        printf("\n- QUERY PARAMETRICHE\n");
        printf("\t5. \n");
        printf("\t6. \n");
        printf("\n----------------------\n");
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

                // chiudiConnessione(conn);

                printf("\nInserisci le nuove credenziali: \n");
                printf("- User: ");
                scanf("%s", PG_USER);
                printf("- Password: ");
                scanf("%s", PG_PASS);
                printf("- Database: ");
                scanf("%s", PG_DATABASE);
                printf("- Host: ");
                scanf("%s", PG_HOST);
                printf("- Port: ");
                scanf("%d", &PG_PORT);

                inizializzaConnessione(conn, PG_USER, PG_PASS, PG_DATABASE,
                                       PG_HOST, PG_PORT);
                break;
            case 2:
                char query[200]="SELECT Email, COUNT(NumeroAnnunci) AS AnnunciPubblicati FROM Utente AS U JOIN Annuncio AS A ON U.Email=A.EmailUtente GROUP BY Email;";
                eseguiQuery(conn, query);
                break;
            case 3:
                break;
            case 4:
                break;
            default:
                break;
        }
    }
}