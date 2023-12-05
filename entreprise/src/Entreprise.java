import java.lang.reflect.Type;
import java.sql.*;
import java.util.InputMismatchException;
import java.util.Scanner;

public class Entreprise {

    private Scanner scanner = new Scanner(System.in);

    private Connection conn = null;

    private String idEntreprise;

    private PreparedStatement encoderOffreStage;
    private PreparedStatement voirMotsCles;
    private PreparedStatement ajouterMotCle;
    private PreparedStatement voirSesOffresStages;
    private PreparedStatement voirCandidatures;
    private PreparedStatement selectionnerEtudiant;
    private PreparedStatement annulerOffreStage;

    private PreparedStatement seConnecter;

    public Entreprise() {

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
            encoderOffreStage = conn.prepareStatement("SELECT projet.encoder_offre_stage (?,?,?)");
            voirMotsCles = conn.prepareStatement("SELECT * FROM projet.voir_mots_cles");
            ajouterMotCle = conn.prepareStatement("SELECT projet.ajouter_mot_cle_offre_stage (?,?)");
            voirSesOffresStages = conn.prepareStatement("SELECT projet.voir_offres_stages_entreprise (?)");
            voirCandidatures = conn.prepareStatement("SELECT projet.voir_candidatures(?,?)");
            selectionnerEtudiant = conn.prepareStatement("SELECT projet.selectionner_etudiant_offre_stage (?,?,?)");
            annulerOffreStage = conn.prepareStatement("SELECT projet.annuler_offre_stage (?)");
            seConnecter = conn.prepareStatement("SELECT mdp FROM projet.entreprise WHERE id_entreprise=?");
        } catch (SQLException e) {
            System.out.println("Erreur !");
            System.exit(1);
        }

    }

    public void start() {

        System.out.println("Application Entreprise");
        System.out.println("Veuillez vous connecter");

        seConnecter();

        int option;

        while(true) {
            System.out.println("1 - Encoder une offre de stage");
            System.out.println("2 - Voir les mots-clés disponibles");
            System.out.println("3 - Ajouter un mot-clé à une offre");
            System.out.println("4 - Voir ses offres de stage");
            System.out.println("5 - Voir les candidatures");
            System.out.println("6 - Selectionner un étudiant");
            System.out.println("7 - Annuler une offre de stage");

            try {
                option = scanner.nextInt();
                scanner.nextLine();
            } catch (InputMismatchException e) {
                scanner.next();
                System.out.println("Entrer un entier!");
                continue;
            }
            if (option < 1 || option > 7) {
                System.out.println("Option inexistante");
                continue;
            }

            switch (option) {
                case 1: encoderOffreStage();
                    break;
                case 2: voirMotsCles();
                    break;
                case 3: ajouterMotCle();
                    break;
                case 4: voirSesOffresStages();
                    break;
                case 5: voirCandidatures();
                    break;
                case 6: selectionnerEtudiant();
                    break;
                case 7: annulerOffreStage();
                    break;
            }
        }

    }

    public void seConnecter() {

        String identifiant, mdp;
        Boolean connecte = false;

        System.out.println("Identifiant: ");
        identifiant = scanner.nextLine();
        System.out.println("Mot de passe: ");
        mdp = scanner.nextLine();
        try {
            seConnecter.setString(1,identifiant);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        while (!connecte) {

            try(ResultSet rs = seConnecter.executeQuery()) {
                while (rs.next()) {
                    if (BCrypt.checkpw(mdp, rs.getString(1))) {
                        connecte = true;
                        setIdEntreprise(identifiant);
                        break;
                    }
                }
                if (!connecte) {
                    System.out.println("\nMauvais identifiants de connexion");
                    System.out.println("Identifiant: ");
                    identifiant = scanner.nextLine();
                    System.out.println("Mot de passe: ");
                    mdp = scanner.nextLine();
                    seConnecter.setString(1,identifiant);
                }
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        }

    }

    public void encoderOffreStage() {

        String description;
        Semestre semestre = null;

        System.out.println("Encoder une offre de stage");
        System.out.println("Description: ");
        description = scanner.nextLine();
        System.out.println("Semestre (\"Q1\",\"Q2\"): ");
        while (semestre == null) {
            try {
                semestre = Semestre.valueOf(scanner.nextLine());
            } catch (IllegalArgumentException e) {
                System.out.println("Semestre inexistant, entrer a nouveau le semestre");
                System.out.println("Semestre (\"Q1\",\"Q2\"): ");
            }
        }

        try {
            encoderOffreStage.setString(1,description);
            encoderOffreStage.setObject(2, semestre, Types.OTHER);
            encoderOffreStage.setString(3,getIdEntreprise());
            encoderOffreStage.executeQuery();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

    }

    public void voirMotsCles() {

        System.out.println("Voir les mots-clés disponibles");

        try(ResultSet rs = voirMotsCles.executeQuery()) {
            System.out.println();
            while (rs.next()) {
                System.out.println(
                        rs.getString(1)
                );
            }
            System.out.println();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    public void ajouterMotCle() {

        String codeOffreStage, motCle;

        System.out.println("Ajouter un mot-clé à une offre");
        System.out.println("Code offre stage: ");
        codeOffreStage = scanner.nextLine();
        System.out.println("Mot clé: ");
        motCle = scanner.nextLine();

        try {
            ajouterMotCle.setString(1,codeOffreStage);
            ajouterMotCle.setString(2,motCle);
            ajouterMotCle.executeQuery();
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }

    }

    public void voirSesOffresStages() {
        System.out.println("Voir ses offres de stage");
    }

    public void voirCandidatures() {
        System.out.println("Voir les candidatures");
    }

    public void selectionnerEtudiant() {
        System.out.println("Selectionner un étudiant");
    }

    public void annulerOffreStage() {
        System.out.println("Annuler une offre de stage");
    }

    public String getIdEntreprise() {
        return idEntreprise;
    }

    public void setIdEntreprise(String idEntreprise) {
        this.idEntreprise = idEntreprise;
    }

}
