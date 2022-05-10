PROCEDURE pr_assign_num_desempat_sinc (p_convocatoria IN number, p_idproces IN number) IS vnomfuncio varchar2 (100) := vnompackage || ‘pr_assignar_numero_desempat’;CURSOR c_obligatoria IS WITH solicituds AS
  (
         SELECT sol.gedacpre_solicitud_id   AS gedacpre_solicitud_id ,
                nvl(existeix_germa,’n’) AS existeix_germa,
                sol.convocatoria_id         AS convocatoria_id,
                sol.ensenyament             AS ensenyament,
                sol.nivell                  AS nivell,
                pet.regim                   AS regim,
                pet.torn                    AS torn ,
                alm.num_doc_tutor1          AS num_doc_tutor1,
                alm.num_doc_tutor2          AS num_doc_tutor2,
                sol.alumne_id               AS alumne_id,
                pet.codi_centre             AS codi_centre
         FROM   gedacpre_solicitud sol ,
                gedacpre_peticio_x_solicitud pet ,
                gedacpre_vw_alumne_sol alm ,
                gedacpre_estat_solicitud est
         WHERE  sol.gedacpre_solicitud_id = pet.gedacpre_solicitud_id
         AND    sol.convocatoria_id = p_convocatoria
         AND    sol.estat_solicitud_id = est.estat_solicitud_id
         AND    sol.alumne_id = alm.id_alumne
         AND    sol.codi_solicitud_pre=alm.codi_solicitud
         AND    pet.ordre_peticio = 1
         AND    ensenyament IN (‘einf’,
                                ’epri’,
                                ’eso’))SELECT   s.gedacpre_solicitud_id
  FROM     solicituds s
  WHERE    (
                    s.existeix_germa = ‘n’
           OR       NOT EXISTS
                    (
                           SELECT 1
                           FROM   solicituds ger_s
                           WHERE  ger_s.existeix_germa = ‘s’
                           AND    s.convocatoria_id = GER_s.convocatoria_id
                           AND    s.ensenyament = GER_s.ensenyament
                           AND    s.nivell = GER_s.nivell
                           AND    s.regim = ger_s.regim
                           AND    s.torn = ger_s.torn
                           AND    s.codi_centre=ger_s.codi_centre
                           AND    ( (
                                                s.num_doc_tutor1 = GER_s.num_doc_tutor1
                                         OR     s.num_doc_tutor1 = GER_s.num_doc_tutor2)
                                  OR     (
                                                s.num_doc_tutor2 = GER_s.num_doc_tutor1
                                         OR     s.num_doc_tutor2 = GER_s.num_doc_tutor2) )
                           AND    GER_s.gedacpre_solicitud_id <> s.gedacpre_solicitud_id
                           AND    GER_s.alumne_id <> s.alumne_id
                           AND    GER_s.gedacpre_solicitud_id < s.gedacpre_solicitud_id ))
  ORDER BY dbms_random.value;v_numero number := 0;CURSOR c_post_obligatoria ISSELECT   gedacpre_solicitud_id
    FROM     gedacpre_solicitud s,
             gedacpre_estat_solicitud e
    WHERE    ensenyament NOT IN (‘einf’,
                                 ’epri’,
                                 ’eso’)
    AND      convocatoria_id = p_convocatoria
    AND      s.estat_solicitud_id = e.estat_solicitud_id
    ORDER BY dbms_random.value;BEGIN
  --afegir_detall(p_idproces,’Inici procés calcular número desempat’, true);
  UPDATE gedacpre_solicitud
  SET    numero_desempat = NULL
  WHERE  convocatoria_id=p_convocatoria;
  
  for r_sol                IN c_obligatoria
  loop v_numero := v_numero + 1;
  UPDATE gedacpre_solicitud
  SET    numero_desempat = v_numero
  WHERE  gedacpre_solicitud_id = r_sol.gedacpre_solicitud_id;

ENDLOOP;COMMIT;MERGE
INTO         gedacpre_solicitud S
using        (
                      --SELECT SOL.GEDACPRE_SOLICITUD_ID, MIN(SOL_GER.NUMERO_DESEMPAT) NUMERO_DESEMPAT
                      SELECT   SOL.gedacpre_solicitud_id,
                               Substr(Min(
                               CASE SOL.estat_solicitud_id
                                        WHEN 1 THEN SOL.estat_solicitud_id+2
                                        ELSE SOL.estat_solicitud_id
                               END
                                        ||SOL_GER.numero_desempat),2) NUMERO_DESEMPAT --Concatenem Estat||Num_Desempat prioritzant estat=2 i treiem estat
                      FROM     gedacpre_solicitud SOL ,
                               gedacpre_peticio_x_solicitud PET ,
                               gedacpre_vw_alumne_sol ALM ,
                               gedacpre_estat_solicitud EST ,
                               gedacpre_solicitud SOL_GER ,
                               gedacpre_peticio_x_solicitud PET_GER ,
                               gedacpre_vw_alumne_sol ALM_GER ,
                               gedacpre_estat_solicitud EST_GER
                      WHERE    SOL.gedacpre_solicitud_id = PET.gedacpre_solicitud_id
                      AND      SOL.estat_solicitud_id = EST.estat_solicitud_id
                      AND      SOL.convocatoria_id = p_convocatoria
                      AND      SOL.alumne_id = ALM.id_alumne
                      AND      SOL.codi_solicitud_pre=ALM.codi_solicitud
                      AND      PET.ordre_peticio = 1
                      AND      SOL.ensenyament IN (‘einf’,
                                                   ’epri’,
                                                   ’eso’)
                      AND      SOL.existeix_germa = ‘s’
                      AND      SOL.numero_desempat IS NULL
                      AND      SOL_GER.gedacpre_solicitud_id = PET_GER.gedacpre_solicitud_id
                      AND      SOL_GER.estat_solicitud_id = EST_GER.estat_solicitud_id
                      AND      SOL_GER.convocatoria_id = p_convocatoria
                      AND      SOL_GER.alumne_id = ALM_GER.id_alumne
                      AND      SOL_GER.codi_solicitud_pre=ALM_GER.codi_solicitud
                      AND      PET_GER.ordre_peticio = 1
                      AND      SOL_GER.ensenyament IN (‘einf’,
                                                       ’epri’,
                                                       ’eso’)
                      AND      SOL_GER.existeix_germa = ‘s’
                      AND      SOL_GER.numero_desempat IS NOT NULL
                      AND      SOL.convocatoria_id = SOL_GER.convocatoria_id
                      AND      pet.codi_centre=PET_GER.codi_centre
                      AND      SOL.ensenyament = SOL_GER.ensenyament
                      AND      SOL.nivell = SOL_GER.nivell
                      AND      PET.regim = PET_GER.regim
                      AND      PET.torn = PET_GER.torn
                      AND      ( (
                                                 ALM.num_doc_tutor1 = ALM_GER.num_doc_tutor1
                                        OR       ALM.num_doc_tutor1 = ALM_GER.num_doc_tutor2)
                               OR       (
                                                 ALM.num_doc_tutor2 = ALM_GER.num_doc_tutor1
                                        OR       ALM.num_doc_tutor2 = ALM_GER.num_doc_tutor2) )
                      AND      SOL.gedacpre_solicitud_id <> SOL_GER.gedacpre_solicitud_id
                      AND      SOL.alumne_id <> SOL_GER.alumne_id
                      GROUP BY SOL.gedacpre_solicitud_id ) TEMP
ON (
                          S.gedacpre_solicitud_id=temp.gedacpre_solicitud_id)
WHEN matched THEN
UPDATE
SET    S.numero_desempat = TEMP.numero_desempat ;COMMIT;
--v_numero := FN_NUMERO_MAX_OBLIGATORIA;
-- no es calculen numeros de desempat de totes les convocatòries barrejant obligatoria i postv_numero := 0;FOR r_sol                IN c_post_obligatoria
loop v_numero := v_numero + 1;UPDATE gedacpre_solicitud
SET    numero_desempat = v_numero
WHERE  gedacpre_solicitud_id = r_sol.gedacpre_solicitud_id;DBMS_OUTPUT.put_line(‘postobligatoria’ || v_numero);END
loop;COMMIT;finalitzar_proces(p_idproces);COMMIT;EXCEPTION
WHEN others THEN
  afegir_detall(p_idproces,’error incontrolat al proc�s d’’assignaci� n�mero desempat. text de l’’error’||sqlerrm||substr(dbms_utility.format_error_backtrace,1,3000), true);finalitzar_proces(p_idproces, true);gedacpre_pg_log.inserir_log(‘error noCONTROLAT: ‘ || sqlerrm, vnomfuncio);END
pr_assign_num_desempat_sinc;