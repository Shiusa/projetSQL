import java.sql.*;
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

        String url="jdbc:postgresql://172.24.2.6:5432/dbtrongnguyen";
        //String url="jdbc:postgresql://localhost:5432/postgres";
        //login trongnguyen
        //mdp AWZJRQDP2
        try {
            conn= DriverManager.getConnection(url,"trongnguyen","AWZJRQDP2");
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

        System.out.println("Application Professeur");

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
                scanner.nextLine();
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

        String nom, prenom, mail, mdp;
        Semestre semestre = null;

        String salt = BCrypt.gensalt();

        System.out.println("Encoder un étudiant");
        System.out.println("Nom: ");

        nom = scanner.nextLine();
        System.out.println("Prénom: ");
        prenom = scanner.nextLine();
        System.out.println("Mail (@student.vinci.be): ");
        mail = scanner.nextLine();
        System.out.println("Semestre (\"Q1\",\"Q2\"): ");
        while (semestre == null) {
            try {
                semestre = Semestre.valueOf(scanner.nextLine());
            } catch (IllegalArgumentException e) {
                System.out.println("Semestre inexistant, entrer a nouveau le semestre");
                System.out.println("Semestre (\"Q1\",\"Q2\"): ");
            }
        }

        System.out.println("Mot de passe: ");
        mdp = BCrypt.hashpw(scanner.nextLine(),salt);

        try {
            encoderEtudiant.setString(1,nom);
            encoderEtudiant.setString(2,prenom);
            encoderEtudiant.setString(3,mail);
            encoderEtudiant.setObject(4, semestre, Types.OTHER);
            encoderEtudiant.setString(5,mdp);
            encoderEtudiant.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    public void encoderEntreprise() {

        String nom, adresse, mail, identifiant, mdp;

        String salt = BCrypt.gensalt();

        System.out.println("Encoder une entreprise");
        System.out.println("Nom: ");
        nom = scanner.nextLine();
        System.out.println("Adresse: ");
        adresse = scanner.nextLine();
        System.out.println("Mail: ");
        mail = scanner.nextLine();
        System.out.println("Identifiant (3 lettres majuscule): ");
        identifiant = scanner.nextLine();

        System.out.println("Mot de passe: ");
        mdp = BCrypt.hashpw(scanner.nextLine(),salt);

        try {
            encoderEntreprise.setString(1,nom);
            encoderEntreprise.setString(2,adresse);
            encoderEntreprise.setString(3,mail);
            encoderEntreprise.setString(4,identifiant);
            encoderEntreprise.setString(5,mdp);
            encoderEntreprise.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void encoderMotCle() {

        String motCle;

        System.out.println("Encoder un mot-clé");
        System.out.println("Mot-clé: ");
        motCle = scanner.nextLine();

        try {
            encoderMotCle.setString(1,motCle);
            encoderMotCle.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void voirOffreInvalide() {

        System.out.println("Voir les offres de stage dans l'état \"non validée\"");

        try(ResultSet rs = voirOffreStage.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        +"Semestre: " + rs.getString(2) + "\n"
                        +"Nom entreprise: " + rs.getString(3) + "\n"
                        +"Description: " + rs.getString(4) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void validerOffre() {

        String codeOffreStage;

        System.out.println("Valider une offre de stage en donnant son code");
        System.out.println("Code offre stage: ");
        codeOffreStage = scanner.nextLine();

        try {
            validerOffreStage.setString(1,codeOffreStage);
            validerOffreStage.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void voirOffreValidee() {

        System.out.println("Voir les offres de stage dans l'état \"validée\"");

        try(ResultSet rs = voirOffreStageValidee.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        +"Semestre: " + rs.getString(2) + "\n"
                        +"Nom entreprise: " + rs.getString(3) + "\n"
                        +"Description: " + rs.getString(4) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void voirEtudiantsSansStage() {

        System.out.println("Voir les étudiants qui n'ont pas de stage");

        try(ResultSet rs = voirEtudiantSansStage.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nNom: " + rs.getString(1) + "\n"
                        +"Prénom: " + rs.getString(2) + "\n"
                        +"Email: " + rs.getString(3) + "\n"
                        +"Semestre: " + rs.getString(4) +"\n"
                        +"Nb candidature en attente: " + rs.getString(5) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void voirOffreAttribuee() {

        System.out.println("Voir les offres de stage dans l'état \"attribuée\"");

        try(ResultSet rs = voirOffreStageAttribuee.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        +"Nom de l'entreprise: " + rs.getString(2) + "\n"
                        +"Nom de l'étudiant: " + rs.getString(3) + "\n"
                        +"Prénom de l'étudiant: " + rs.getString(4) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

}