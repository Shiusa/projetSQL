import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class Professeur {

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


}