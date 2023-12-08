import java.sql.*;
import java.util.InputMismatchException;
import java.util.Scanner;

public class Etudiant {
    private Scanner scanner = new Scanner(System.in);

    private String email;
    private Semestre semestre;
    private int idEtudiant;

    private Connection conn = null;
    private PreparedStatement connecterEtudiant;
    private PreparedStatement visualiserOffresStageValides;
    private PreparedStatement rechercherOffreStageMotsCle;
    private PreparedStatement poserCandidature;

    private PreparedStatement  getIdEtudiant;

    private PreparedStatement getOffresEtudiant;
    private PreparedStatement annulerCandidature;
    private PreparedStatement recupererInfoEtudiant;


    public Etudiant() {

        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }

        String url="jdbc:postgresql://172.24.2.6:5432/dbtrongnguyen";
        //String url = "jdbc:postgresql://localhost:5432/postgres";
        //login jsp
        //mdp jsp
        try {
            conn = DriverManager.getConnection(url, "jasonchu", "JKWZUA2EF");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }

        try {
            connecterEtudiant = conn.prepareStatement("SELECT projet.connecter_etudiant (?,?)");
            visualiserOffresStageValides = conn.prepareStatement("SELECT * FROM projet.visualiser_offres_stage_valides (?) t(code VARCHAR(5), nom VARCHAR(100), adresse VARCHAR(100), description VARCHAR(1000), mots VARCHAR)");
            rechercherOffreStageMotsCle = conn.prepareStatement("SELECT * FROM projet.rechercher_offre_stage_mots_cle (?,?) t(code VARCHAR(5), nom VARCHAR(100), adresse VARCHAR(100), description VARCHAR(1000), mots VARCHAR)");
            poserCandidature = conn.prepareStatement("SELECT projet.poser_candidature (?,?,?)");
            getOffresEtudiant = conn.prepareStatement("SELECT * FROM projet.get_offres_etudiant(?) t(code VARCHAR(5), nom VARCHAR(100), etat VARCHAR(100))");
            annulerCandidature = conn.prepareStatement("SELECT projet.annuler_candidature(?,?)");
            recupererInfoEtudiant = conn.prepareStatement("SELECT * FROM projet.etudiants WHERE email=?");

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
            System.out.println("1 - Visualiser les offres de stages valides");
            System.out.println("2 - Rechercher des offres de stages par mots clés");
            System.out.println("3 - Poser une candidature");
            System.out.println("4 - Voir les offres de stage de l'étudiant");
            System.out.println("5 - Annuler une candidature");


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
        boolean login = false;
        String mail, mdp;

        while (!login) {
            System.out.println("Email: ");
            mail = scanner.nextLine();
            System.out.println("Mot de passe: ");
            mdp = scanner.nextLine();

            try {
                recupererInfoEtudiant.setString(1, mail);
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }

            try (ResultSet resultSet = recupererInfoEtudiant.executeQuery()) {
                while (resultSet.next()) {
                    if (BCrypt.checkpw(mdp, resultSet.getString(6))) {
                        login = true;
                        setIdEtudiant(resultSet.getInt(1));
                        setEmail(resultSet.getString(4));
                        setSemestre(Semestre.valueOf(resultSet.getString(5)));
                        break;
                    }
                }
                if (!login) {
                    System.out.println("Mauvais identifiant de connexion!");
                    System.out.println("Veuillez-vous reconnecter");
                }
            } catch (SQLException throwables) {
                throwables.printStackTrace();
            }
        }
    }



    public void visualiserOffresStageValides() {

        System.out.println("Visualiser Offres de stage valides");

        try {
            visualiserOffresStageValides.setObject(1, getSemestre(), Types.OTHER);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

        try(ResultSet rs = visualiserOffresStageValides.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        +"Entreprise: " + rs.getString(2) + "\n"
                        +"Adresse: " + rs.getString(3) + "\n"
                        +"Description: " + rs.getString(4) +"\n"
                        +"Mots-clés: " + rs.getString(5) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    private void rechercherOffreStageMotsCle() {

        String motCle;

        System.out.println("Rechercher offre stage par mot-clé");
        System.out.println("Mot-clé: ");
        motCle = scanner.nextLine();

        try {
            rechercherOffreStageMotsCle.setString(1, motCle);
            rechercherOffreStageMotsCle.setObject(2, getSemestre(), Types.OTHER);
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

        try(ResultSet rs = rechercherOffreStageMotsCle.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        +"Entreprise: " + rs.getString(2) + "\n"
                        +"Adresse: " + rs.getString(3) + "\n"
                        +"Description: " + rs.getString(4) +"\n"
                        +"Mots-clés: " + rs.getString(5) +"\n"
                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
    }

    private void poserCandidature() {

        String codeOffreStage, motivation;

        System.out.println("Poser une candidature");

        System.out.println("Code offre stage: ");
        codeOffreStage = scanner.nextLine();

        System.out.println("Motivation: ");
        motivation = scanner.nextLine();

        try {
            poserCandidature.setString(1, codeOffreStage);
            poserCandidature.setString(2, motivation);
            poserCandidature.setInt(3, getIdEtudiant());
            poserCandidature.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }


    private void getOffresEtudiant() {

        System.out.println("Voir ses offres de stage");


        try {
            getOffresEtudiant.setInt(1, getIdEtudiant());
        } catch (SQLException e) {
            e.printStackTrace();
        }

        try (ResultSet rs = getOffresEtudiant.executeQuery()) {
            while (rs.next()) {
                System.out.println(
                        "\nCode: " + rs.getString(1) + "\n"
                        + "Entreprise: " + rs.getString(2) + "\n"
                        + "Etat candidature: " + rs.getString(3) + "\n"

                );
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }


    }





    public void annulerCandidature() {

        String codeOffreStage;


        System.out.println("Annuler une offre de stage");
        System.out.println("Code offre stage: ");
        codeOffreStage = scanner.nextLine();

        try {
            annulerCandidature.setString(1,codeOffreStage);
            annulerCandidature.setString(2,getEmail());
            annulerCandidature.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    public int getIdEtudiant() {
        return idEtudiant;
    }

    public String getEmail() {
        return email;
    }

    public Semestre getSemestre() {
        return semestre;
    }

    public void setIdEtudiant(int idEtudiant) {
        this.idEtudiant = idEtudiant;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setSemestre(Semestre semestre) {
        this.semestre = semestre;
    }
}
