DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

-- Vérifier si le type ENUM existe avant de le créer
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'semestre') THEN
        CREATE TYPE semestre AS ENUM ('Q1', 'Q2');
    END IF;
END $$;


CREATE TABLE projet.etudiants (
    id_etudiant SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL CHECK (nom<>''),
    prenom VARCHAR(100) NOT NULL CHECK (prenom<>''),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email<>''),
    CHECK ( email LIKE '%@student.vinci.be'),
    semestre semestre NOT NULL,
    mdp VARCHAR(100) NOT NULL
);

CREATE TABLE projet.entreprise (
    id_entreprise CHAR(3) PRIMARY KEY CHECK ( id_entreprise SIMILAR TO '[A-Z]{3}'),
    nom VARCHAR(100) NOT NULL CHECK (nom<>''),
    adresse VARCHAR(100) NOT NULL CHECK (adresse<>''),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email<>''),
    mdp VARCHAR(100) NOT NULL
);

CREATE TABLE projet.etats (
    id_etat SERIAL PRIMARY KEY,
    etat VARCHAR(100) NOT NULL UNIQUE CHECK (etat<>'')
);

CREATE TABLE projet.mots_cles (
    id_mot_cle SERIAL PRIMARY KEY,
    mot VARCHAR(100) NOT NULL UNIQUE CHECK (mot<>'')
);

CREATE TABLE projet.offres_stage (
    id_offre_stage SERIAL PRIMARY KEY,
    code VARCHAR(5) NOT NULL UNIQUE CHECK ( code SIMILAR TO (offres_stage.entreprise || '\d')),
    entreprise CHAR(3) REFERENCES projet.entreprise(id_entreprise) NOT NULL,
    etat INTEGER REFERENCES projet.etats(id_etat) NOT NULL,
    etudiant INTEGER REFERENCES projet.etudiants(id_etudiant) NULL UNIQUE,
    nb_candidature INTEGER DEFAULT 0,
    semestre semestre NOT NULL,
    description VARCHAR(1000) NOT NULL
);

CREATE TABLE projet.candidatures (
    offre_stage INTEGER REFERENCES projet.offres_stage(id_offre_stage) NOT NULL,
    code_offre_stage VARCHAR(5) NOT NULL UNIQUE CHECK ( code_offre_stage SIMILAR TO (candidatures.offre_stage || '\d')),
    etudiant INTEGER REFERENCES projet.etudiants(id_etudiant) NOT NULL,
    CONSTRAINT candidatures_pk PRIMARY KEY (offre_stage, etudiant),
    etat INTEGER REFERENCES projet.etats(id_etat) NOT NULL,
    motivations VARCHAR(1000) NOT NULL
);

CREATE TABLE projet.offre_mot (
    offre_stage INTEGER REFERENCES projet.offres_stage(id_offre_stage) NOT NULL,
    mot_cle INTEGER REFERENCES projet.mots_cles(id_mot_cle) NOT NULL,
    CONSTRAINT offre_mot_pk PRIMARY KEY (offre_stage, mot_cle)
);


INSERT INTO projet.etats (etat) VALUES ('non validée');
INSERT INTO projet.etats (etat) VALUES ('validée');
INSERT INTO projet.etats (etat) VALUES ('attribuée');
INSERT INTO projet.etats (etat) VALUES ('annulée');

INSERT INTO projet.etats (etat) VALUES ('en attente');
INSERT INTO projet.etats (etat) VALUES ('acceptée');
INSERT INTO projet.etats (etat) VALUES ('refusée');


/*CREATE OR REPLACE FUNCTION get_offres_non_validees()
RETURNS TABLE (
    code VARCHAR(5),
    semestre semestre,
    entreprise_nom VARCHAR(100),
    description_etat VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT os.code, os.semestre, e.nom AS entreprise_nom, et.etat AS description_etat
    FROM projet.offres_stage os
    JOIN projet.etats et ON os.etat = et.id_etat
    JOIN projet.entreprise e ON os.entreprise = e.id_entreprise
    WHERE et.etat = 'non validée';
END;
$$ LANGUAGE plpgsql;*/

--professeur Q1
CREATE OR REPLACE FUNCTION projet.encoder_etudiant(_nom VARCHAR(100), _prenom VARCHAR(100), _email VARCHAR(100), _semestre semestre, _mdp VARCHAR(100))
RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.etudiants(nom, prenom, email, semestre, mdp) VALUES (_nom, _prenom, _email, _semestre, _mdp);
end;
$$ LANGUAGE plpgsql;


--professeur Q2
CREATE OR REPLACE FUNCTION projet.encoder_entreprise(_nom VARCHAR(100), _adresse VARCHAR(100), _email VARCHAR(100), _id CHAR(3), _mdp VARCHAR(100))
RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.entreprise(id_entreprise, nom, adresse, email, mdp) VALUES (_id, _nom, _adresse, _email, _mdp);
end;
$$ LANGUAGE plpgsql;


--professeur Q3
CREATE OR REPLACE FUNCTION projet.encoder_mot_cle(p_mot VARCHAR(100))
RETURNS VOID
AS $$
BEGIN
    -- Insérer le mot-clé dans la table
    INSERT INTO projet.mots_cles (mot) VALUES (p_mot);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION encoder_mot_cle_trigger()
RETURNS TRIGGER
AS $$
BEGIN
    IF EXISTS(SELECT mot FROM projet.mots_cles WHERE mot = NEW.mot)
        THEN RAISE 'Mot clé déjà présent';
    END IF;
    RETURN NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encoder_mot_cle_trigger BEFORE INSERT ON projet.mots_cles
FOR EACH ROW
EXECUTE PROCEDURE encoder_mot_cle_trigger();


--professeur Q4
CREATE OR REPLACE VIEW projet.get_offres_non_validees AS
    SELECT os.code, os.semestre, en.nom AS entreprise_nom, os.description
    FROM projet.offres_stage os, projet.etats et, projet.entreprise en
    WHERE(os.entreprise = en.id_entreprise AND os.etat = et.id_etat)
    AND(et.etat = 'non validée');


--professeur Q5
CREATE OR REPLACE FUNCTION projet.valider_offre_stage(_code VARCHAR(5))
RETURNS VOID
AS $$
BEGIN
    UPDATE projet.offres_stage
    SET etat = (SELECT etat FROM projet.etats WHERE etat = 'validée')
    WHERE code = _code;
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION valider_offre_stage_trigger()
RETURNS TRIGGER
AS $$
BEGIN
    IF (NEW.etat <> (SELECT etat FROM projet.etats WHERE etat = 'non validée'))
    THEN
        RAISE 'ce stage ne peut pas etre validée';
    end if;
    RETURN NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valider_offre_stage_trigger BEFORE UPDATE ON projet.offres_stage
FOR EACH ROW
EXECUTE PROCEDURE valider_offre_stage_trigger ();


--professeur Q6
CREATE OR REPLACE VIEW projet.get_offres_validees AS
    SELECT os.code, os.semestre, e.nom AS entreprise_nom, et.etat AS description_etat
    FROM projet.offres_stage os
    JOIN projet.etats et ON os.etat = et.id_etat
    JOIN projet.entreprise e ON os.entreprise = e.id_entreprise
    WHERE et.etat = 'validée';


--professeur Q7
CREATE OR REPLACE VIEW projet.voir_etudiant_sans_stage AS
    SELECT et.nom, et.prenom, et.email, et.semestre, count(ca.*)
    FROM projet.etudiants et LEFT OUTER JOIN projet.candidatures ca on et.id_etudiant = ca.etudiant
    WHERE (et.id_etudiant NOT IN (
        SELECT ca2.etudiant
        FROM projet.candidatures ca2, projet.etats et
        WHERE (ca2.etat = et.id_etat)
        AND (et.etat = 'acceptée')))
    GROUP BY et.nom, et.prenom, et.email, et.semestre;


--professeur Q8
CREATE OR REPLACE VIEW projet.voir_offre_stage_attribue AS
    SELECT os.code, en.nom as "nom entreprise", et.nom as "nom etudiant", et.prenom
    FROM projet.offres_stage os, projet.entreprise en, projet.etudiants et
    WHERE (os.entreprise = en.id_entreprise AND os.etudiant = et.id_etudiant)
    AND (os.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'attribué'));



--entreprise Q1
CREATE OR REPLACE FUNCTION projet.encoder_offre_stage(_description VARCHAR(1000), _semestre semestre, _entreprise CHAR(3))
RETURNS VOID AS $$
DECLARE
    numero_code INTEGER;
    etat_defaut INTEGER;
    code_offre  VARCHAR(5);
BEGIN
    /*IF EXISTS (
        SELECT os.* FROM projet.offres_stage os
        WHERE (os.entreprise = _entreprise)
        AND(os.semestre = _semestre)
        AND (os.etat = (SELECT etat FROM projet.etats WHERE etats.etat = 'attribuée')))
        THEN RAISE 'Offre de stage déjà attribuée durant ce semestre';
    END IF;*/

    SELECT count(os.id_offre_stage)+1 FROM projet.offres_stage os WHERE (os.entreprise = _entreprise) INTO numero_code;
    SELECT et.id_etat FROM projet.etats et WHERE et.etat = 'non validée' INTO etat_defaut;
    code_offre:= concat(_entreprise,numero_code);

    INSERT INTO projet.offres_stage(code, entreprise, etat, semestre, description) VALUES (code_offre, _entreprise, etat_defaut, _semestre, _description);
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION encoder_offre_stage_trigger()
RETURNS TRIGGER
AS $$
BEGIN
    IF EXISTS (
        SELECT os.* FROM projet.offres_stage os
        WHERE (os.entreprise = NEW.entreprise)
        AND(os.semestre = NEW.semestre)
        AND (os.etat = (SELECT id_etat FROM projet.etats WHERE etats.etat = 'attribuée')))
        THEN RAISE 'Offre de stage déjà attribuée durant ce semestre';
    END IF;
    RETURN NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encoder_offre_stage_trigger BEFORE INSERT ON projet.offres_stage
FOR EACH ROW
EXECUTE PROCEDURE encoder_offre_stage_trigger();


--entreprise Q2
CREATE OR REPLACE VIEW projet.visualiser_mots_cles AS
    SELECT mc.mot
    FROM projet.mots_cles mc;


--entreprise Q3
CREATE OR REPLACE FUNCTION projet.ajouter_mot_cle_offre_stage(_code_offre_stage VARCHAR(5), _mot_cle VARCHAR(100))
RETURNS VOID AS $$
DECLARE
    mot_cle_id INTEGER;
    offre_stage_id INTEGER;
    etat_attribuee INTEGER;
    etat_annulee INTEGER;
    etat_os INTEGER;
BEGIN
    SELECT id_offre_stage FROM projet.offres_stage WHERE (code = _code_offre_stage) INTO offre_stage_id;
    SELECT id_mot_cle FROM projet.mots_cles WHERE (mot = _mot_cle) INTO mot_cle_id;
    SELECT id_etat FROM projet.etats WHERE etat = 'attribuée' INTO etat_attribuee;
    SELECT id_etat FROM projet.etats WHERE etat = 'attribuée' INTO etat_annulee;
    SELECT os.etat FROM projet.offres_stage os WHERE (os.code = _code_offre_stage) INTO etat_os;
    IF (etat_os = etat_annulee OR etat_os = etat_attribuee)
        THEN RAISE 'Impossible d''ajouter un mot-clé à une offre dans l''état attribuée ou annulée';
    END IF;

    INSERT INTO projet.offre_mot(offre_stage, mot_cle) VALUES (offre_stage_id, mot_cle_id);
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ajouter_mot_cle_offre_stage_trigger()
RETURNS TRIGGER
AS $$
DECLARE
    mot_cle_count INTEGER;
BEGIN

    SELECT count(om.*) FROM projet.offre_mot om WHERE (om.offre_stage = NEW.offre_stage) INTO mot_cle_count;

    IF NOT EXISTS (
        SELECT os.* FROM projet.offres_stage os WHERE os.id_offre_stage = NEW.offre_stage
        )
    THEN RAISE 'Aucune offre de stage trouvée avec le code spécifié.';
    END IF;
    IF NOT EXISTS (
        SELECT mc.* FROM projet.mots_cles mc WHERE mc.id_mot_cle = NEW.mot_cle
        )
    THEN RAISE 'Le mot-clé spécifié n''est pas valide.';
    END IF;
    IF (mot_cle_count >=3)
        THEN RAISE 'L''offre de stage a atteint le nombre maximum de mots-clés (3).';
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouter_mot_cle_offre_stage_trigger BEFORE INSERT ON projet.offre_mot
FOR EACH ROW
EXECUTE PROCEDURE ajouter_mot_cle_offre_stage_trigger();


--entreprise Q4
CREATE OR REPLACE FUNCTION get_offres_stages_entreprise(p_id_entreprise CHAR(3))
RETURNS TABLE (
    code_offre VARCHAR,
    description VARCHAR,
    semestre semestre,
    etat VARCHAR,
    nb_candidatures_en_attente INTEGER,
    nom_etudiant_attribue VARCHAR
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.code,
        o.description,
        o.semestre,
        e.etat,
        COUNT(c.offre_stage) AS nb_candidatures_en_attente,
        COALESCE(CONCAT(et.nom, ' ', et.prenom), 'pas attribuée') AS nom_etudiant_attribue
    FROM
        projet.offres_stage o
    JOIN
        projet.etats e ON o.etat = e.id_etat
    LEFT JOIN
        projet.candidatures c ON o.id_offre_stage = c.offre_stage AND c.etat IS NULL
    LEFT JOIN
        projet.etudiants et ON o.etudiant = et.id_etudiant
    WHERE
        o.entreprise = p_id_entreprise
    GROUP BY
        o.code, o.description, o.semestre, e.etat, et.nom, et.prenom;

    RETURN;
END;
$$ LANGUAGE plpgsql;


--entreprise Q5
CREATE OR REPLACE FUNCTION projet.voir_candidatures(_code_offre_stage VARCHAR(5), _entreprise CHAR(3))
RETURNS SETOF RECORD
AS $$
DECLARE
    sortie RECORD;
    candidatures_rec RECORD;
    id_entreprise CHAR(3);
BEGIN
    id_entreprise := SUBSTRING(_code_offre_stage FROM 1 FOR 3);
    IF id_entreprise != _entreprise
        THEN RAISE'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
    END IF;
    IF NOT EXISTS(
        SELECT * FROM projet.offres_stage WHERE (projet.offres_stage.code=_code_offre_stage AND projet.offres_stage.entreprise = _entreprise)
        ) THEN RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
    END IF;
    IF NOT EXISTS(
        SELECT * FROM projet.candidatures WHERE (projet.candidatures.code_offre_stage = _code_offre_stage)
        ) THEN RAISE 'Il n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
    END IF;


    FOR candidatures_rec IN SELECT * FROM projet.candidatures WHERE (code_offre_stage = _code_offre_stage)
    LOOP
        SELECT ca.etat, et.nom, et.prenom, et.email, ca.motivations
        FROM candidatures_rec ca, projet.etudiants et
        WHERE (ca.etudiant = et.id_etudiant)
        AND(ca.code_offre_stage = _code_offre_stage)
        INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;
end;
$$ LANGUAGE plpgsql;


--entreprise Q6
CREATE OR REPLACE FUNCTION projet.voir_candidatures_offre_stage(p_code_offre VARCHAR)
RETURNS TABLE (
    etat VARCHAR(100),
    nom_etudiant VARCHAR(100),
    prenom_etudiant VARCHAR(100),
    email_etudiant VARCHAR(100),
    motivations VARCHAR(1000)
)
AS $$
BEGIN
-- Vérifier si le code correspond à une offre de l'entreprise
    IF NOT EXISTS (
        SELECT 1
        FROM projet.offres_stage o, projet.candidatures c
        WHERE o.code = p_code_offre OR c.code_offre_stage
    ) THEN
        RAISE NOTICE 'l n''y a pas de candidatures pour cette offre ou vous n''avez pas d''offre ayant ce code';
        RETURN;
    END IF;

    -- Sélectionner les candidatures pour l'offre de stage spécifiée
    RETURN QUERY
    SELECT
        c.etat,
        e.nom AS nom_etudiant,
        e.prenom AS prenom_etudiant,
        e.email AS email_etudiant,
        c.motivations
    FROM
        projet.candidatures c
    JOIN
        projet.etudiants e ON c.etudiant = e.id_etudiant
    JOIN
        projet.offres_stage o ON c.offre_stage = o.id_offre_stage
    WHERE
        o.code = p_code_offre;
end;
$$ LANGUAGE plpgsql;


--entreprise Q7
CREATE OR REPLACE FUNCTION annuler_offre_stage(p_code_offre VARCHAR)
RETURNS VOID
AS $$
DECLARE
    v_offre_id INTEGER;
BEGIN
    -- Vérifier si l'offre de stage existe et appartient à l'entreprise
    SELECT id_offre_stage
    INTO v_offre_id
    FROM projet.offres_stage o
    WHERE o.code = p_code_offre
    AND o.etat NOT IN (SELECT id_etat FROM projet.etats WHERE etat IN ('attribuée', 'annulée'));

    IF v_offre_id IS NULL THEN
        RAISE EXCEPTION 'L''offre de stage avec le code spécifié n''existe pas ou ne peut pas être annulée.';
    END IF;

    -- Mettre à jour l'état de l'offre de stage à "annulée"
    UPDATE projet.offres_stage
    SET etat = (SELECT id_etat FROM projet.etats WHERE etat = 'annulée')
    WHERE id_offre_stage = v_offre_id;

    -- Mettre à jour l'état des candidatures en attente à "refusée"
    UPDATE projet.candidatures
    SET etat = (SELECT id_etat FROM projet.etats WHERE etat = 'refusée')
    WHERE offre_stage = v_offre_id;

    RAISE NOTICE 'L''offre de stage a été annulée avec succès.';
END;
$$ LANGUAGE plpgsql;


--eleve Q0
CREATE OR REPLACE FUNCTION projet.connecter_etudiant(_email VARCHAR(100), _mot_de_passe VARCHAR(100))
RETURNS BOOLEAN AS $$
DECLARE
    est_valide BOOLEAN;
BEGIN
    -- Vérifier si l'e-mail et le mot de passe correspondent à un étudiant
    SELECT TRUE INTO est_valide
    FROM projet.etudiants
    WHERE email = _email AND mdp = _mot_de_passe;

    RETURN est_valide;
END;
$$ LANGUAGE plpgsql;


--eleve Q1
CREATE OR REPLACE FUNCTION projet.visualiser_offres_stage_valides(_semestre semestre)
RETURNS TABLE (
    code_offre VARCHAR,
    nom_entreprise VARCHAR,
    adresse_entreprise VARCHAR,
    description TEXT,
    mots_cles TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        os.code AS code_offre,
        e.nom AS nom_entreprise,
        e.adresse AS adresse_entreprise,
        os.description,
        mc.mot AS mots_cles -- pour concaténer les mots-clés
    FROM
        projet.offres_stage os
    JOIN
        projet.entreprise e ON os.entreprise = e.id_entreprise
    JOIN
        projet.offre_mot om ON os.id_offre_stage = om.offre_stage
    JOIN
        projet.mots_cles mc ON om.mot_cle = mc.id_mot_cle
    JOIN
        projet.etats et ON os.etat = et.id_etat
    WHERE
        et.etat = 'Validée' AND os.semestre = _semestre
    GROUP BY
        os.code, e.nom, e.adresse, os.description, mc.mot
    ORDER BY
        os.code;
END;
$$ LANGUAGE plpgsql;


--eleve Q2
CREATE OR REPLACE FUNCTION projet.rechercher_offre_stage_mots_cle(_mot_cle VARCHAR, _semestre semestre)
RETURNS TABLE (
    code_offre VARCHAR,
    nom_entreprise VARCHAR,
    adresse_entreprise VARCHAR,
    description TEXT,
    mots_cles TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT os.code AS code_offre,
    e.nom AS nom_entreprise,
    e.adresse AS adresse_entreprise,
    os.description,
    mc.mot AS mots_cles

    FROM
        projet.offres_stage os
    JOIN
        projet.offre_mot om ON os.id_offre_stage = om.offre_stage
    JOIN
        projet.mots_cles mc ON om.mot_cle = mc.id_mot_cle
    JOIN
        projet.entreprise e ON os.entreprise = e.id_entreprise
    WHERE
        mc.mot = _mot_cle
    AND
        os.semestre = _semestre
    AND
        os.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'Validée');
END;
$$ LANGUAGE plpgsql;


--eleve Q3
/*CREATE OR REPLACE FUNCTION projet.poser_candidature(_code_stage CHAR(8), _motivations TEXT) RETURNS VOID AS $$
BEGIN
    INSERT INTO projet.candidatures (code_offre_stage, motivations)
    VALUES (_code_stage, _motivations);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.poser_candidature_trigger () RETURNS TRIGGER AS $$
DECLARE
BEGIN
    -- Vérifie si l'étudiant n'a pas déjà une candidature acceptée
     IF EXISTS (SELECT * FROM projet.etudiants et
        JOIN
         candidatures c on et.id_etudiant = c.etudiant
        join
         etats e on c.etat = e.id_etat
        WHERE
            e.etat = 'validée')
    THEN
        RAISE 'Déjà une candidature acceptée';
    END IF;

    -- Vérifier s'il a déjà posé une candidature pour cette offre
    IF EXISTS (
        SELECT *
        FROM
            projet.candidatures ca
        JOIN
            etudiants e on e.id_etudiant = ca.etudiant
        JOIN offres_stage o on o.id_offre_stage = ca.offre_stage
        WHERE candidatures.code_offre_stage = NEW.code_offre_stage
    )
    THEN
        RAISE 'Vous avez déjà posé une candidature pour cette offre.';
    END IF;

    -- Vérifier si l'offre n'est pas déjà validée avec un autre étudiant
        IF EXISTS (
            SELECT * FROM offres_stage os
            JOIN projet.etats e ON os.etat = e.id_etat
            WHERE e.etat = 'validée'
            )
        THEN
            RAISE 'Offre déjà validée par autrui';
        END IF;

      -- Vérifier si l'offre correspond au bon semestre
    IF NOT EXISTS (
        SELECT *
        FROM projet.offres_stage os
        JOIN candidatures c on os.id_offre_stage = c.offre_stage
        JOIN etudiants e on e.id_etudiant = c.etudiant
        WHERE os.id_offre_stage = NEW.code_offre_stage
        AND semestre = e.semestre
    )
    THEN
        RAISE 'L''offre ne correspond pas au bon semestre.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER poser_candidature_trigger BEFORE INSERT ON projet.candidatures
    FOR EACH ROW
    EXECUTE PROCEDURE projet.poser_candidature_trigger();*/

CREATE OR REPLACE FUNCTION projet.poser_candidature(_code_stage VARCHAR(5), _motivations TEXT, _etudiant INTEGER)
RETURNS VOID
AS $$
DECLARE
    offre_stage_id INTEGER;
    etat_id INTEGER;
BEGIN
    SELECT os.id_offre_stage FROM projet.offres_stage os WHERE (os.code = _code_stage) INTO offre_stage_id;
    SELECT et.id_etat FROM projet.etats et WHERE (et.etat = 'en attente') INTO etat_id;
    INSERT INTO projet.candidatures(offre_stage, code_offre_stage, etudiant, etat, motivations) VALUES (offre_stage_id,_code_stage,_etudiant,etat_id,_motivations);
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poser_candidature_trigger()
RETURNS TRIGGER
AS $$
DECLARE
    etat_acceptee_id INTEGER;
    etat_validee_id INTEGER;
    semestre_var semestre;
BEGIN
    SELECT et.id_etat FROM projet.etats et WHERE (et.etat = 'acceptée') INTO etat_acceptee_id;
    SELECT et.id_etat FROM projet.etats et WHERE (et.etat = 'validée') INTO etat_validee_id;
    SELECT et.semestre FROM projet.etudiants et WHERE (et.id_etudiant = NEW.etudiant) INTO semestre_var;
    IF EXISTS (
        SELECT ca.* FROM projet.candidatures ca
        WHERE (ca.etudiant = NEW.etudiant)
        AND (ca.etat = etat_acceptee_id)
        )
        THEN RAISE 'Déjà une candidature acceptée';
    END IF;
    IF EXISTS(
        SELECT ca.* FROM projet.candidatures ca
        WHERE (ca.offre_stage = NEW.offre_stage AND ca.code_offre_stage = NEW.code_offre_stage AND ca.etudiant = NEW.etudiant)
        )
        THEN RAISE 'Candidature déjà posé pour cette offre';
    END IF;
    IF (
        SELECT os.etat FROM projet.offres_stage os
        WHERE(os.id_offre_stage = NEW.offre_stage AND os.code = NEW.code_offre_stage)
        ) <> etat_validee_id
        THEN RAISE 'Offre non validée';
    END IF;
    IF (
        SELECT os.semestre FROM projet.offres_stage os
        WHERE(os.id_offre_stage = NEW.offre_stage AND os.code = NEW.code_offre_stage)
        ) <> semestre_var
        THEN RAISE 'Mauvais semestre';
    END IF;

end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER poser_candidature_trigger BEFORE INSERT ON projet.candidatures
FOR EACH ROW
EXECUTE PROCEDURE poser_candidature_trigger();

--eleve
CREATE OR REPLACE FUNCTION incrementer_nb_candidature()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE projet.offres_stage
    SET nb_candidature = nb_candidature + 1
    WHERE (projet.offres_stage.id_offre_stage = NEW.offre_stage AND projet.offres_stage.code = NEW.code_offre_stage);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_nb_candidature AFTER INSERT ON projet.candidatures
FOR EACH ROW
EXECUTE PROCEDURE incrementer_nb_candidature();


--eleve Q4
CREATE OR REPLACE FUNCTION projet.get_offres_etudiant(_id_etudiant INTEGER)
RETURNS TABLE (
    code_offre VARCHAR(5),
    nom_entreprise VARCHAR(100),
    etat_candidature VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT os.code AS code_offre, e.nom AS nom_entreprise, c.etat AS etat_candidature
    FROM projet.offres_stage os
    JOIN projet.entreprise e ON os.entreprise = e.id_entreprise
    LEFT JOIN projet.candidatures c ON os.id_offre_stage = c.offre_stage AND c.etudiant = _id_etudiant;
END;
$$ LANGUAGE plpgsql;


--eleve Q5
CREATE OR REPLACE FUNCTION annuler_candidature(_code_offre_stage VARCHAR(5), _id_etudiant INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Vérifier si la candidature est en attente
    IF EXISTS (
        SELECT *
        FROM projet.candidatures c
        WHERE c.code_offre_stage = _code_offre_stage
          AND c.etudiant = _id_etudiant
          AND c.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'en attente')
    ) THEN
        -- Annuler la candidature
        DELETE FROM projet.candidatures
        WHERE code_offre_stage = _code_offre_stage
          AND etudiant = _id_etudiant;
    ELSE
        RAISE EXCEPTION 'La candidature ne peut être annulée que si elle est en attente.';
    END IF;
END;
$$ LANGUAGE plpgsql;