import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.InputMismatchException;
import java.util.Scanner;

public class Professeur {

    private Scanner scanner = new Scanner(System.in);

    private Connection conn = null;
    private PreparedStatement encoderEtudiant;
    private PreparedStatement encoderEntreprise;
    private PreparedStatement encoderMotCle;
    private PreparedStatement voirOffreStage;
    private PreparedStatement validerOffreStage;
    private PreparedStatement voirOffreStageValidee;
    private PreparedStatement voirEtudiantSansStage;
    private PreparedStatement voirOffreStageAttribuee;

    public Professeur() {

        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }

        //String url="jdbc:postgresql://172.24.2.6:5432/trongnguyen";
        String url="jdbc:postgresql://localhost:5432/postgres";
        try {
            conn= DriverManager.getConnection(url,"postgres","test");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }

        try {
            encoderEtudiant = conn.prepareStatement("SELECT projet.encoder_etudiant (?,?,?,?,?)");
            encoderEntreprise = conn.prepareStatement("SELECT projet.encoder_entreprise (?,?,?,?,?)");
            encoderMotCle = conn.prepareStatement("SELECT projet.encoder_mot_cle (?)");
            voirOffreStage = conn.prepareStatement("SELECT * FROM projet.get_offres_non_validees");
            validerOffreStage = conn.prepareStatement("SELECT projet.valider_offre_stage(?)");
            voirOffreStageValidee = conn.prepareStatement("SELECT * FROM projet.get_offres_validees");
            voirEtudiantSansStage = conn.prepareStatement("SELECT * FROM projet.voir_etudiant_sans_stage");
            voirOffreStageAttribuee = conn.prepareStatement("SELECT * FROM projet.voir_offre_stage_attribue");
        } catch (SQLException e) {
            System.out.println("Erreur !");
            System.exit(1);
        }

    }


    public void start() {

        int option;

        while(true) {
            System.out.println("1 - Encoder un étudiant");
            System.out.println("2 - Encoder une entreprise");
            System.out.println("3 - Encoder un mot-clé");
            System.out.println("4 - Voir les offres de stage dans l'état \"non validée\"");
            System.out.println("5 - Valider une offre de stage en donnant son code");
            System.out.println("6 - Voir les offres de stage dans l'état \"validée\"");
            System.out.println("7 - Voir les étudiants qui n'ont pas de stage");
            System.out.println("8 - Voir les offres de stage dans l'état \"attribuée\"");

            try {
                option = scanner.nextInt();
            } catch (InputMismatchException e) {
                scanner.next();
                System.out.println("Entrer un entier!");
                continue;
            }
            if (option < 1 || option > 8) {
                System.out.println("Option inexistante");
                continue;
            }

            switch (option) {
                case 1: encoderEtudiant();
                    break;
                case 2: encoderEntreprise();
                    break;
                case 3: encoderMotCle();
                    break;
                case 4: voirOffreInvalide();
                    break;
                case 5: validerOffre();
                    break;
                case 6: voirOffreValidee();
                    break;
                case 7: voirEtudiantsSansStage();
                    break;
                case 8: voirOffreAttribuee();
                    break;
            }
        }

    }

    public void encoderEtudiant() {
        System.out.println("Encoder un étudiant");
    }

    public void encoderEntreprise() {
        System.out.println("Encoder une entreprise");
    }

    private void encoderMotCle() {
        System.out.println("Encoder un mot clé");
    }

    private void voirOffreInvalide() {
        System.out.println("Voir les offres de stage dans l'état \"non validée\"");
    }

    private void validerOffre() {
        System.out.println("Valider une offre de stage en donnant son code");
    }

    private void voirOffreValidee() {
        System.out.println("Voir les offres de stage dans l'état \"validée\"");
    }

    private void voirEtudiantsSansStage() {
        System.out.println("Voir les étudiants qui n'ont pas de stage");
    }

    private void voirOffreAttribuee() {
        System.out.println("Voir les offres de stage dans l'état \"attribuée\"");
    }

}