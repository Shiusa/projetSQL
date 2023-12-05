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
            voirMotsCles = conn.prepareStatement("SELECT * FROM projet.visualiser_mots_cles");
            ajouterMotCle = conn.prepareStatement("SELECT projet.ajouter_mot_cle_offre_stage (?,?,?)");
            voirSesOffresStages = conn.prepareStatement("SELECT projet.get_offres_stages_entreprise (?)");
            voirCandidatures = conn.prepareStatement("SELECT projet.voir_candidatures(?,?)");
            //selectionnerEtudiant = conn.prepareStatement("SELECT * FROM projet.get_offres_validees");
            annulerOffreStage = conn.prepareStatement("SELECT projet.annuler_offre_stage (?)");
            seConnecter = conn.prepareStatement("SELECT mdp FROM projet.entreprise WHERE id_entreprise=?");
        } catch (SQLException e) {
            System.out.println("Erreur !");
            System.exit(1);
        }

    }

    public void start() {

        String identifiant, mdp;
        Boolean connecte = false;

        System.out.println("Application Entreprise");

        System.out.println("Veuillez vous connecter");
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
                        setIdEntreprise(idEntreprise);
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

    public void encoderOffreStage() {
        System.out.println("Encoder une offre de stage");
    }

    public void voirMotsCles() {
        System.out.println("Voir les mots-clés disponibles");
    }

    public void ajouterMotCle() {
        System.out.println("Ajouter un mot-clé à une offre");
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
