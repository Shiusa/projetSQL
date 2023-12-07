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
    code_offre_stage VARCHAR(5) NOT NULL,
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

    IF NOT EXISTS(
        SELECT * FROM projet.offres_stage WHERE code = _code
        )
        THEN RAISE 'Cette offre n''existe pas';
    END IF;
    IF ((SELECT os.etat FROM projet.offres_stage os WHERE os.code = _code) <> (SELECT id_etat FROM projet.etats WHERE etat = 'non validée'))
    THEN
        RAISE 'ce stage ne peut pas etre validée';
    END IF;

    UPDATE projet.offres_stage
    SET etat = (SELECT id_etat FROM projet.etats WHERE etat = 'validée')
    WHERE code = _code;
end;
$$ LANGUAGE plpgsql;

/*CREATE OR REPLACE FUNCTION valider_offre_stage_trigger()
RETURNS TRIGGER
AS $$
BEGIN
    IF (OLD.etat <> (SELECT id_etat FROM projet.etats WHERE etat = 'non validée'))
    THEN
        RAISE 'ce stage ne peut pas etre validée';
    end if;
    RETURN NEW;
end;
$$ LANGUAGE plpgsql;

CREATE TRIGGER valider_offre_stage_trigger BEFORE UPDATE ON projet.offres_stage
FOR EACH ROW
EXECUTE PROCEDURE valider_offre_stage_trigger ();*/


--professeur Q6
CREATE OR REPLACE VIEW projet.get_offres_validees AS
    SELECT os.code, os.semestre, en.nom AS entreprise_nom, os.description
    FROM projet.offres_stage os, projet.etats et, projet.entreprise en
    WHERE(os.entreprise = en.id_entreprise AND os.etat = et.id_etat)
    AND(et.etat = 'validée');


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
    AND (os.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'attribuée'));



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
CREATE OR REPLACE VIEW projet.voir_mots_cles AS
    SELECT mc.mot
    FROM projet.mots_cles mc;


--entreprise Q3
CREATE OR REPLACE FUNCTION projet.ajouter_mot_cle_offre_stage(_code_offre_stage VARCHAR(5), _mot_cle VARCHAR(100), _entreprise CHAR(3))
RETURNS VOID AS $$
DECLARE
    mot_cle_id INTEGER;
    offre_stage_id INTEGER;
    etat_attribuee INTEGER;
    etat_annulee INTEGER;
    etat_os INTEGER;
    id_entreprise CHAR(3);
BEGIN
    id_entreprise := SUBSTRING(_code_offre_stage FROM 1 FOR 3);
    IF id_entreprise != _entreprise
    THEN RAISE'Vous n''avez pas d''offre ayant ce code';
    END IF;
    IF NOT EXISTS(
            SELECT * FROM projet.offres_stage WHERE (projet.offres_stage.code=_code_offre_stage AND projet.offres_stage.entreprise = _entreprise)
        ) THEN RAISE 'Vous n''avez pas d''offre ayant ce code';
    END IF;

    SELECT id_offre_stage FROM projet.offres_stage WHERE (code = _code_offre_stage) INTO offre_stage_id;
    SELECT id_mot_cle FROM projet.mots_cles WHERE (mot = _mot_cle) INTO mot_cle_id;
    SELECT id_etat FROM projet.etats WHERE etat = 'attribuée' INTO etat_attribuee;
    SELECT id_etat FROM projet.etats WHERE etat = 'annulée' INTO etat_annulee;
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
    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouter_mot_cle_offre_stage_trigger BEFORE INSERT ON projet.offre_mot
FOR EACH ROW
EXECUTE PROCEDURE ajouter_mot_cle_offre_stage_trigger();


--entreprise Q4
/*CREATE OR REPLACE FUNCTION projet.voir_offres_stages_entreprise(_id_entreprise CHAR(3))
RETURNS TABLE (
    code_offre VARCHAR,
    description VARCHAR,
    semestre semestre,
    etat VARCHAR,
    nb_candidatures_en_attente BIGINT,
    nom_etudiant_attribue TEXT
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
        o.entreprise = _id_entreprise
    GROUP BY
        o.code, o.description, o.semestre, e.etat, et.nom, et.prenom;

    RETURN;
END;
$$ LANGUAGE plpgsql;*/

CREATE OR REPLACE FUNCTION projet.voir_offres_stages_entreprise(_entreprise CHAR(3))
RETURNS SETOF RECORD
AS $$
DECLARE
    sortie RECORD;
    offres_rec RECORD;
BEGIN

    FOR offres_rec IN
        SELECT os.code, os.description, os.semestre, ea.etat::VARCHAR(100), os.nb_candidature, coalesce(et.nom, 'pas attribuée')::TEXT AS "etudiant"
        FROM projet.offres_stage os LEFT OUTER JOIN projet.etudiants et on os.etudiant = et.id_etudiant
        LEFT OUTER JOIN projet.etats ea on os.etat = ea.id_etat
        WHERE (os.entreprise = _entreprise)
    LOOP
        SELECT offres_rec.code, offres_rec.description, offres_rec.semestre,offres_rec.etat, offres_rec.nb_candidature, offres_rec.etudiant INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;

end;
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


    FOR candidatures_rec IN
        SELECT ea.etat, et.nom, et.prenom, et.email, ca.motivations
        FROM projet.candidatures ca, projet.etudiants et, projet.etats ea
        WHERE (ca.etudiant = et.id_etudiant AND ca.etat = ea.id_etat)
        AND(ca.code_offre_stage = _code_offre_stage)
    LOOP
        SELECT candidatures_rec.etat, candidatures_rec.nom, candidatures_rec.prenom, candidatures_rec.email, candidatures_rec.motivations INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;
end;
$$ LANGUAGE plpgsql;


--entreprise Q6
/*CREATE OR REPLACE FUNCTION projet.selectionner_etudiant_offre_stage(_id_entreprise CHAR(3), _code_offre VARCHAR, _email_etudiant VARCHAR)
    RETURNS VOID
AS $$
DECLARE
    v_offre_id INTEGER;
    v_etudiant_id INTEGER;
    v_semestre semestre;
    v_entreprise CHAR(3);
BEGIN
    -- Vérifier si l'offre de stage existe, appartient à l'entreprise, et est dans l'état "validée"
    SELECT
        o.id_offre_stage, o.semestre, o.entreprise
    INTO
        v_offre_id, v_semestre, v_entreprise
    FROM
        projet.offres_stage o
    WHERE
            o.code = _code_offre
      AND o.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'validée')
      AND o.entreprise = _id_entreprise;

    IF v_offre_id IS NULL THEN
        RAISE EXCEPTION 'L''offre de stage spécifiée ne peut pas être attribuée.';
    END IF;

    -- Vérifier si l'étudiant a une candidature en attente pour cette offre
    SELECT
        e.id_etudiant
    INTO
        v_etudiant_id
    FROM
        projet.etudiants e
            JOIN
        projet.candidatures c ON e.id_etudiant = c.etudiant
    WHERE
            e.email = _email_etudiant
      AND c.offre_stage = v_offre_id
      AND c.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'en attente');

    IF v_etudiant_id IS NULL THEN
        RAISE EXCEPTION 'L''étudiant spécifié n''a pas de candidature en attente pour cette offre.';
    END IF;

    -- Mettre à jour l'état de l'offre de stage à "attribuée"
    UPDATE
        projet.offres_stage
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'attribuée')
    WHERE
            id_offre_stage = v_offre_id;

    -- Mettre à jour l'état de la candidature de l'étudiant à "acceptée"
    UPDATE
        projet.candidatures
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'acceptée')
    WHERE
            offre_stage = v_offre_id AND etudiant = v_etudiant_id;

    -- Mettre à jour l'état des autres candidatures en attente de l'étudiant à "annulée"
    UPDATE
        projet.candidatures
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'annulée')
    WHERE
            etudiant = v_etudiant_id AND offre_stage <> v_offre_id;

    -- Mettre à jour l'état des autres candidatures en attente pour cette offre à "refusée"
    UPDATE
        projet.candidatures
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'refusée')
    WHERE
            offre_stage = v_offre_id;

    -- Mettre à jour l'état des autres offres de l'entreprise durant ce semestre à "annulée"
    UPDATE
        projet.offres_stage
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'annulée')
    WHERE
            entreprise = v_entreprise
      AND semestre = v_semestre
      AND id_offre_stage <> v_offre_id
      AND etat <> (SELECT id_etat FROM projet.etats WHERE etat = 'annulée');

    -- Mettre à jour l'état des candidatures en attente pour les autres offres annulées à "refusée"
    UPDATE
        projet.candidatures
    SET
        etat = (SELECT id_etat FROM projet.etats WHERE etat = 'refusée')
    WHERE
            offre_stage IN (
            SELECT
                id_offre_stage
            FROM
                projet.offres_stage
            WHERE
                    entreprise = v_entreprise
              AND semestre = v_semestre
              AND id_offre_stage <> v_offre_id
              AND etat = (SELECT id_etat FROM projet.etats WHERE etat = 'annulée')
        );

    RAISE NOTICE 'L''offre de stage a été attribuée à l''étudiant avec succès.';
END;
$$ LANGUAGE plpgsql;*/

CREATE OR REPLACE FUNCTION projet.selectionner_etudiant_offre_stage(_entreprise CHAR(3), _code_offre_stage VARCHAR(5), _email_etudiant VARCHAR(100))
RETURNS VOID
AS $$
DECLARE
    v_id_entreprise CHAR(3);
    etat_validee INTEGER;
    etat_attente INTEGER;
    etat_attribuee INTEGER;
    etat_acceptee INTEGER;
    etat_annulee INTEGER;
    etat_refusee INTEGER;
    offre_etat INTEGER;
    candidature_etat INTEGER;
    v_id_etudiant INTEGER;
    semestre_etudiant semestre;
    candidature_sel_rec RECORD;
    candidature_non_sel_rec RECORD;
    offre_stage_annule_rec RECORD;
    candidature_offre_annule_rec RECORD;
BEGIN
    v_id_entreprise := SUBSTRING(_code_offre_stage FROM 1 FOR 3);
    IF v_id_entreprise != _entreprise
        THEN RAISE'Vous n''avez pas d''offre ayant ce code';
    END IF;
    IF NOT EXISTS(
            SELECT * FROM projet.offres_stage WHERE (projet.offres_stage.code=_code_offre_stage AND projet.offres_stage.entreprise = _entreprise)
        ) THEN RAISE 'Vous n''avez pas d''offre ayant ce code';
    END IF;

    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'validée') INTO etat_validee;
    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'en attente') INTO etat_attente;
    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'attribuée') INTO etat_attribuee;
    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'acceptée') INTO etat_acceptee;
    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'annulée') INTO etat_annulee;
    SELECT id_etat FROM projet.etats WHERE (projet.etats.etat = 'refusée') INTO etat_refusee;
    SELECT etat FROM projet.offres_stage WHERE (projet.offres_stage.code=_code_offre_stage AND projet.offres_stage.entreprise = _entreprise) INTO offre_etat;
    SELECT id_etudiant, semestre FROM projet.etudiants WHERE (projet.etudiants.email = _email_etudiant) INTO v_id_etudiant, semestre_etudiant;
    SELECT etat FROM projet.candidatures WHERE (projet.candidatures.etudiant = v_id_etudiant AND projet.candidatures.code_offre_stage = _code_offre_stage) INTO candidature_etat;

    IF offre_etat != etat_validee
        THEN RAISE 'Vous n''avez pas d''offre ayant ce code';
    END IF;
    IF candidature_etat != etat_attente
        THEN RAISE 'La candidature n''est pas en attente';
    END IF;

    UPDATE projet.offres_stage
    SET etat = etat_attribuee, etudiant = v_id_etudiant
    WHERE (code = _code_offre_stage);

    UPDATE projet.candidatures
    SET etat = etat_acceptee
    WHERE (etudiant = v_id_etudiant AND code_offre_stage = _code_offre_stage);

    FOR candidature_sel_rec IN
        SELECT * FROM projet.candidatures
        WHERE (etudiant = v_id_etudiant)
        AND(code_offre_stage <> _code_offre_stage)
    LOOP
        UPDATE projet.candidatures
        SET etat = etat_annulee
        WHERE (etudiant = v_id_etudiant)
        AND(offre_stage = candidature_sel_rec.offre_stage);
    END LOOP;

    FOR candidature_non_sel_rec IN
        SELECT * FROM projet.candidatures
        WHERE (etudiant <> v_id_etudiant)
        AND(code_offre_stage = _code_offre_stage)
    LOOP
        UPDATE projet.candidatures
        SET etat = etat_refusee
        WHERE (etudiant = candidature_non_sel_rec.etudiant)
        AND(offre_stage = candidature_non_sel_rec.offre_stage);
    END LOOP;

    FOR offre_stage_annule_rec IN
        SELECT * FROM projet.offres_stage
        WHERE (offres_stage.entreprise = _entreprise)
        AND (offres_stage.etat <> etat_attribuee)
        AND(semestre = semestre_etudiant)
    LOOP
        UPDATE projet.offres_stage
        SET etat = etat_annulee
        WHERE (id_offre_stage = offre_stage_annule_rec.id_offre_stage);

        FOR candidature_offre_annule_rec IN
            SELECT * FROM projet.candidatures
            WHERE (offre_stage = offre_stage_annule_rec.id_offre_stage)
        LOOP
            UPDATE projet.candidatures
            SET etat = etat_refusee
            WHERE (offre_stage = candidature_offre_annule_rec.offre_stage);
        END LOOP;

    END LOOP;

END;
$$ LANGUAGE plpgsql;



--entreprise Q7
CREATE OR REPLACE FUNCTION projet.annuler_offre_stage(_code_offre_stage VARCHAR, _entreprise CHAR(3))
RETURNS VOID
AS $$
DECLARE
    v_offre_id INTEGER;
    candidature_rec RECORD;
    v_id_entreprise CHAR(3);
BEGIN
    v_id_entreprise := SUBSTRING(_code_offre_stage FROM 1 FOR 3);
    IF v_id_entreprise != _entreprise
    THEN RAISE'Vous n''avez pas d''offre ayant ce code';
    END IF;
    IF NOT EXISTS(
            SELECT * FROM projet.offres_stage WHERE (projet.offres_stage.code=_code_offre_stage AND projet.offres_stage.entreprise = _entreprise)
        ) THEN RAISE 'Vous n''avez pas d''offre ayant ce code';
    END IF;
    -- Vérifier si l'offre de stage existe et appartient à l'entreprise
    SELECT id_offre_stage
    INTO v_offre_id
    FROM projet.offres_stage o
    WHERE o.code = _code_offre_stage
    AND o.etat NOT IN (SELECT id_etat FROM projet.etats WHERE etat IN ('attribuée', 'annulée'));

    IF v_offre_id IS NULL THEN
        RAISE EXCEPTION 'L''offre de stage avec le code spécifié n''existe pas ou ne peut pas être annulée.';
    END IF;

    -- Mettre à jour l'état de l'offre de stage à "annulée"
    UPDATE projet.offres_stage
    SET etat = (SELECT id_etat FROM projet.etats WHERE etat = 'annulée')
    WHERE id_offre_stage = v_offre_id;

    -- Mettre à jour l'état des candidatures en attente à "refusée"
    FOR candidature_rec IN
        SELECT * FROM projet.candidatures WHERE (candidatures.code_offre_stage = _code_offre_stage)
    LOOP
        UPDATE projet.candidatures
        SET etat = (SELECT id_etat FROM projet.etats WHERE etat = 'refusée')
        WHERE offre_stage = candidature_rec.offre_stage
        AND(etudiant = candidature_rec.etudiant);
    END LOOP;

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
/*CREATE OR REPLACE FUNCTION projet.visualiser_offres_stage_valides(_semestre semestre)
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
$$ LANGUAGE plpgsql;*/

CREATE OR REPLACE FUNCTION projet.visualiser_offres_stage_valides(_semestre semestre)
RETURNS SETOF RECORD
AS $$
DECLARE
    sortie RECORD;
    offre_rec RECORD;
    offre_mot_rec RECORD;
    mots VARCHAR;
    sep VARCHAR;
    etat_valide INTEGER;
BEGIN
    SELECT id_etat FROM projet.etats WHERE (etat = 'validée') INTO etat_valide;
    FOR offre_rec IN
        SELECT os.code, en.nom, en.adresse, os.description, os.id_offre_stage
        FROM projet.offres_stage os, projet.entreprise en
        WHERE (os.entreprise = en.id_entreprise)
        AND(os.semestre = _semestre)
        AND(os.etat = etat_valide)
    LOOP
        mots:='';
        sep:='';
        FOR offre_mot_rec IN
            SELECT mc.mot
            FROM projet.mots_cles mc, projet.offre_mot om
            WHERE (mc.id_mot_cle = om.mot_cle AND om.offre_stage = offre_rec.id_offre_stage)
        LOOP
            mots:=mots || sep || offre_mot_rec.mot;
            sep:=', ';
        END LOOP;
        SELECT offre_rec.code, offre_rec.nom, offre_rec.adresse, offre_rec.description, mots INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;
end;
$$ LANGUAGE plpgsql;

--eleve Q2
/*CREATE OR REPLACE FUNCTION projet.rechercher_offre_stage_mots_cle(_mot_cle VARCHAR, _semestre semestre)
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
$$ LANGUAGE plpgsql;*/

CREATE OR REPLACE FUNCTION projet.rechercher_offre_stage_mots_cle(_mot_cle VARCHAR, _semestre semestre)
RETURNS SETOF RECORD
AS $$
DECLARE
    sortie RECORD;
    offre_rec RECORD;
    offre_mot_rec RECORD;
    mots VARCHAR;
    sep VARCHAR;
    etat_valide INTEGER;
BEGIN
    SELECT id_etat FROM projet.etats WHERE (etat = 'validée') INTO etat_valide;
    FOR offre_rec IN
        SELECT os.code, en.nom, en.adresse, os.description, os.id_offre_stage
        FROM projet.offres_stage os, projet.entreprise en, projet.mots_cles mc1, projet.offre_mot om1
        WHERE (os.entreprise = en.id_entreprise AND om1.offre_stage = os.id_offre_stage AND om1.mot_cle = mc1.id_mot_cle)
        AND(os.semestre = _semestre)
        AND(os.etat = etat_valide)
        AND(mc1.mot = _mot_cle)
    LOOP
        mots:='';
        sep:='';
        FOR offre_mot_rec IN
            SELECT mc.mot
            FROM projet.mots_cles mc, projet.offre_mot om
            WHERE (mc.id_mot_cle = om.mot_cle AND om.offre_stage = offre_rec.id_offre_stage)
        LOOP
            mots:=mots || sep || offre_mot_rec.mot;
            sep:=', ';
        END LOOP;
        SELECT offre_rec.code, offre_rec.nom, offre_rec.adresse, offre_rec.description, mots INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;
end;
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
    IF NOT EXISTS(
        SELECT os.* FROM projet.offres_stage os
        WHERE (os.code = NEW.code_offre_stage)
        )
        THEN RAISE 'Offre stage inexistante';
    END IF;
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
    RETURN NEW;
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
/*CREATE OR REPLACE FUNCTION projet.get_offres_etudiant(_email VARCHAR(100))
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
         LEFT JOIN projet.candidatures c ON os.id_offre_stage = c.offre_stage
         JOIN projet.etudiants et ON c.etudiant = et.id_etudiant
WHERE et.email = _email;
END;
$$ LANGUAGE plpgsql;*/

CREATE OR REPLACE FUNCTION projet.get_offres_etudiant(_id_etudiant INTEGER)
RETURNS SETOF RECORD
AS $$
DECLARE
    sortie RECORD;
    offres_rec RECORD;
BEGIN
    FOR offres_rec IN
        SELECT os.code, en.nom, ea.etat::VARCHAR(100)
        FROM projet.offres_stage os, projet.etats ea, projet.etudiants et, projet.entreprise en, projet.candidatures ca
        WHERE (os.entreprise = en.id_entreprise AND ca.offre_stage = os.id_offre_stage AND ca.etudiant = _id_etudiant AND ca.etat = ea.id_etat)
    LOOP
        SELECT offres_rec.code, offres_rec.nom, offres_rec.etat INTO sortie;
        RETURN NEXT sortie;
    END LOOP;
    RETURN;
end;
$$ LANGUAGE plpgsql;


--eleve Q5
--eleve Q5
CREATE OR REPLACE FUNCTION projet.annuler_candidature(_code_offre_stage VARCHAR(5), _email_etudiant VARCHAR(100))
RETURNS VOID AS $$
DECLARE
    etat_annulee INTEGER;
BEGIN
    SELECT id_etat FROM projet.etats WHERE (etat = 'annulée') INTO etat_annulee;
    -- Vérifier si la candidature est en attente
    IF EXISTS (
        SELECT *
        FROM projet.candidatures c
        JOIN projet.etudiants e ON c.etudiant = e.id_etudiant
        WHERE c.code_offre_stage = _code_offre_stage
          AND e.email = _email_etudiant
          AND c.etat = (SELECT id_etat FROM projet.etats WHERE etat = 'en attente')
    ) THEN
        -- Annuler la candidature
        UPDATE projet.candidatures
        SET etat = etat_annulee
        WHERE code_offre_stage = _code_offre_stage AND etudiant = (
                    SELECT id_etudiant
                    FROM projet.etudiants
                    WHERE email = _email_etudiant
                );
    ELSE
            RAISE EXCEPTION 'La candidature ne peut être annulée que si elle est en attente.';
    END IF;
END;
$$ LANGUAGE plpgsql;



/*GRANT CONNECT ON DATABASE /**/ TO jasonchu;
GRANT USAGE ON SCHEMA projet to jasonchu;

GRANT SELECT ON ALL TABLES IN SCHEMA projet TO jasonchu;

GRANT SELECT ON projet.voir_mots_cles TO jasonchu;

GRANT INSERT ON TABLE projet.offre_mot TO jasonchu;
GRANT INSERT ON TABLE projet.offres_stage TO jasonchu;

GRANT UPDATE ON TABLE projet.offres_stage TO jasonchu;
GRANT UPDATE ON TABLE projet.candidatures TO jasonchu;*/

/*SELECT projet.encoder_etudiant ('De','Jean','j.d@student.vinci.be','Q2',?);
SELECT projet.encoder_etudiant ('Du','Marc','m.d@student.vinci.be','Q1',?);

SELECT projet.encoder_mot_cle('Java');
SELECT projet.encoder_mot_cle('Web');
SELECT projet.encoder_mot_cle('Python');

SELECT projet.encoder_entreprise('VINCI', 'Clos Chapelle-aux-Champs 43', 'VIN', 'mdp');

SELECT projet.encoder_offre_stage ('stage SAP', 'Q2', 'VIN');
SELECT projet.encoder_offre_stage ('stage BI', 'Q2', 'VIN');
SELECT projet.encoder_offre_stage ('stage Unity', 'Q2', 'VIN');
SELECT projet.encoder_offre_stage ('stage IA', 'Q2', 'VIN');
SELECT projet.encoder_offre_stage ('stage mobile', 'Q1', 'VIN');

-- valider stage VIN1, VIN4, VIN5
SELECT projet.ajouter_mot_cle_offre_stage ('VIN3', 'Jave', 'VIN');
SELECT projet.ajouter_mot_cle_offre_stage ('VIN5', 'Jave', 'VIN');

SELECT projet.poser_candidature ('VIN4', 'motivation', 1);
SELECT projet.poser_candidature ('VIN5', 'motivation', 2);

SELECT projet.encoder_entreprise('ULB', 'Solbosch', 'ULB', 'mdp');
SELECT projet.encoder_offre_stage ('stage javascript', 'Q2', 'VIN');*/
--valider stage ULB1
