import java.sql.*;
import java.util.InputMismatchException;
import java.util.Scanner;

public class Etudiant {
    private Scanner scanner = new Scanner(System.in);

    private String idEtudiant;

    private String salt = BCrypt.gensalt();

    private Connection conn = null;
    private PreparedStatement connecterEtudiant;
    private PreparedStatement visualiserOffresStageValides;
    private PreparedStatement rechercherOffreStageMotsCle;
    private PreparedStatement poserCandidature;

    private PreparedStatement getOffresEtudiant;
    private PreparedStatement annulerCandidature;


    public Etudiant() {

        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }

        //String url="jdbc:postgresql://172.24.2.6:5432/trongnguyen";
        String url = "jdbc:postgresql://localhost:5432/postgres";
        try {
            conn = DriverManager.getConnection(url, "postgres", "test");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }

        try {
            connecterEtudiant = conn.prepareStatement("SELECT projet.connecter_etudiant (?,?)");
            visualiserOffresStageValides = conn.prepareStatement("SELECT projet.visualiser_offres_stage_valides (?)");
            rechercherOffreStageMotsCle = conn.prepareStatement("SELECT projet.rechercher_offre_stage_mots_cle (?,?)");
            poserCandidature = conn.prepareStatement("SELECT projet.poser_candidature (?,?,?)");
            getOffresEtudiant = conn.prepareStatement("SELECT projet.get_offres_etudiant(?)");
            annulerCandidature = conn.prepareStatement("SELECT annuler_candidature(?,?)");

        } catch (SQLException e) {
            System.out.println("Erreur !");
            System.exit(1);
        }

    }


    public void start() {

        System.out.println("Application Etudiant");
        System.out.println("Veuillez vous connecter");
        connecterEtudiant();

        int option;

        while (true) {
            System.out.println("1 - Se connecter");
            System.out.println("2 - Visualiser les offres de stages valides");
            System.out.println("3 - Rechercher des offres de stages par mots clés");
            System.out.println("4 - Poser une candidature");
            System.out.println("5 - Voir les offres de stage de l'étudiant");
            System.out.println("6 - Annuler une candidature");


            try {
                option = scanner.nextInt();
                scanner.nextLine();
            } catch (InputMismatchException e) {
                scanner.next();
                System.out.println("Entrer un entier!");
                continue;
            }
            if (option < 1 || option > 5) {
                System.out.println("Option inexistante");
                continue;
            }

            switch (option) {
                case 1:
                    visualiserOffresStageValides();
                    break;
                case 2:
                    rechercherOffreStageMotsCle();
                    break;
                case 3:
                    poserCandidature();
                    break;
                case 4:
                    getOffresEtudiant();
                    break;
                case 5:
                    annulerCandidature();
                    break;

            }
        }

    }



    private void connecterEtudiant() {
        String email, mdp;
        boolean connecte = false;


        System.out.println("Se connecter");
        System.out.println("Email: ");
        email = scanner.nextLine();

        System.out.println("Mot de passe: ");
        mdp = BCrypt.hashpw(scanner.nextLine(), salt);

        try {
            connecterEtudiant.setString(1, email);
            connecterEtudiant.setString(2, mdp);
            connecterEtudiant.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }


    }


    public void visualiserOffresStageValides() {

        Semestre semestre;

        System.out.println("Visualiser Offres de stage valides");
        System.out.println("Semestre (Q1/Q2): ");
        //Rajouter un illegalArgumentException si pas bio
        String inputSemestre = scanner.nextLine();
        while (inputSemestre == null) {
            try {
                visualiserOffresStageValides.setString(1, inputSemestre);
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            } catch (IllegalArgumentException e) {
                System.out.println("Saisie invalide");

            }
        }
    }

    private void rechercherOffreStageMotsCle() {

        String motCle;
        Semestre semestre;

        System.out.println("Encoder un mot-clé");
        System.out.println("Mot-clé: ");
        motCle = scanner.nextLine();

        System.out.println("Encoder semestre");
        System.out.println("Semestre (Q1/Q2): ");

        String inputSemestre = scanner.nextLine();

        try {
            rechercherOffreStageMotsCle.setString(1, motCle);
            rechercherOffreStageMotsCle.setString(2, inputSemestre);
            rechercherOffreStageMotsCle.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        } catch (IllegalArgumentException e) {
            System.out.println("Saisie invalide");

        }

        private void poserCandidature() {
            String codeOffreStage, motivation;
            int etudiant;
            System.out.println("Poser une candidature");

            System.out.println("Code offre stage: ");
            codeOffreStage = scanner.nextLine();

            System.out.println("Motivation: ");
            motivation = scanner.nextLine();

            System.out.println("ID étudiant: ");
            etudiant = scanner.nextInt();

            try {
                poserCandidature.setString(1,codeOffreStage);
                poserCandidature.setString(2,motivation);
                poserCandidature.setInt(2,etudiant);

                poserCandidature.executeQuery();
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }


        }



            private void getOffresEtudiant() {

            int etudiant;
            System.out.println("Voir ses offres de stage");
            System.out.println("ID étudiant: ");
            etudiant = scanner.nextInt();

            try {
                getOffresEtudiant.setInt(etudiant);
            } catch (SQLException e) {
                e.printStackTrace();
            }

            try(ResultSet rs = getOffresEtudiant.executeQuery()) {
                while (rs.next()) {
                    System.out.println(
                            "\nCode: " + rs.getString(1) + "\n"
                                    +"Entreprise: " + rs.getString(2) + "\n"
                                    +"Etat candidature: " + rs.getString(3) + "\n"

                    );
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }



            }



            private void voirOffreValidee() {

                System.out.println("Voir les offres de stage dans l'état \"validée\"");

                try (ResultSet rs = voirOffreStageValidee.executeQuery()) {
                    while (rs.next()) {
                        System.out.println(
                                "\nCode: " + rs.getString(1) + "\n"
                                        + "Semestre: " + rs.getString(2) + "\n"
                                        + "Nom entreprise: " + rs.getString(3) + "\n"
                                        + "Description: " + rs.getString(4) + "\n"
                        );
                    }
                } catch (SQLException throwables) {
                    throwables.printStackTrace();
                }

            }

            private void voirEtudiantsSansStage () {

                System.out.println("Voir les étudiants qui n'ont pas de stage");

                try (ResultSet rs = voirEtudiantSansStage.executeQuery()) {
                    while (rs.next()) {
                        System.out.println(
                                "\nNom: " + rs.getString(1) + "\n"
                                        + "Prénom: " + rs.getString(2) + "\n"
                                        + "Email: " + rs.getString(3) + "\n"
                                        + "Semestre: " + rs.getString(4) + "\n"
                                        + "Nb candidature en attente: " + rs.getString(5) + "\n"
                        );
                    }
                } catch (SQLException throwables) {
                    throwables.printStackTrace();
                }

            }

            private void voirOffreAttribuee () {

                System.out.println("Voir les offres de stage dans l'état \"attribuée\"");

                try (ResultSet rs = voirOffreStageAttribuee.executeQuery()) {
                    while (rs.next()) {
                        System.out.println(
                                "\nCode: " + rs.getString(1) + "\n"
                                        + "Nom de l'entreprise: " + rs.getString(2) + "\n"
                                        + "Nom de l'étudiant: " + rs.getString(3) + "\n"
                                        + "Prénom de l'étudiant: " + rs.getString(4) + "\n"
                        );
                    }
                } catch (SQLException throwables) {
                    throwables.printStackTrace();
                }

            }

        }

    }

    public PreparedStatement getConnecterEtudiant() {
        return connecterEtudiant;
    }

    public String getIdEtudiant() {
        return idEtudiant;
    }

    public void setIdEtudiant(String idEtudiant) {
        this.idEtudiant = idEtudiant;
    }

}
