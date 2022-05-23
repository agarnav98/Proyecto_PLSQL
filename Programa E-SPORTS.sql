-- PROGRAMA E-SPORTS
--ALBERTO GARC�A NAVARRO 1�CFGS DAW

-- PROGRAMA QUE GENERAR� LOS PARTIDOS DE UNA COMPETICI�N DE FORMA AUTOM�TICA Y MOSTRAR� EL EQUIPO GANADOR Y SUS JUGADORES

-- SENTENCIA PARA QUE SE MUESTRE CORRECTAMENTE LOS DATOS POR PANTALLA
SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.PROCEDIMIENTO QUE RECIBE COMO PAR�METRO UNA COMPETICI�N Y GENERAMOS LOS PARTIDOS QUE SE VAN A JUGAR CON LOS EQUIPOS QUE HAY EN LA TABLA 'EQUIPOS'
CREATE OR REPLACE PROCEDURE generar_partidos (p_competicion competiciones.nombre_competicion%TYPE) IS
    -- CURSOR EXPL�CITO QUE VA OBTENER TODOS LOS C�DIGOS DE LOS EQUIPOS
    CURSOR c_equipos IS SELECT cod_equipo FROM equipos;
    -- VARIABLES QUE GUARDAN LOS REGISTROS DE C_EQUIPOS
    v_equipo1 c_equipos%ROWTYPE;
    v_equipo2 c_equipos%ROWTYPE;
    -- EL C�DIGO M�XIMO QUE HAY EN LA TABLA 'EQUIPOS'
    v_maximo equipos.cod_equipo%TYPE := 0;
    -- VARIABLE QUE GENERAR� LOS C�DIGOS DE LOS PARTIDOS DE FORMA CONSECUTIVA
    v_partido NUMBER(3) := 0;
    -- VARIABLE QUE GUARDA EL C�DIGO DE COMPETICI�N
    v_competicion competiciones.cod_competicion%TYPE;
    -- CONTADOR PARA LLEVAR EL BUCLE DE GENERAR PARTIDOS
    v_contador NUMBER(3) := 0;
BEGIN
    -- BORRAMOS TODO LO QUE HUBIESE EN LA TABLA 'PARTIDOS'
    DELETE FROM partidos;
    -- CURSOR IMPL�CITO PARA GUARDAR EN UNA VARIABLE EL C�DIGO DE LA COMPETICI�N PASADA POR PAR�METRO
    SELECT cod_competicion INTO v_competicion FROM competiciones WHERE UPPER(nombre_competicion) = UPPER(p_competicion);
    -- CURSOR IMPL�CITO QUE GUARDA EN UNA VARIABLE EL �LTIMO C�DIGO DEL EQUIPO DE LA TABLA 'EQUIPOS'
    SELECT MAX(cod_equipo) INTO v_maximo FROM EQUIPOS;
    -- BUCLE QUE VA GENERANDO CADA PARTIDO
    OPEN c_equipos;
    LOOP
        -- GUARDAMOS EN UNA VARIABLE EL C�DIGO DEL PRIMER EQUIPO
        FETCH c_equipos INTO v_equipo1;
        -- EL BUCLE ACABAR� AL LLEGAR AL PEN�LTIMO C�DIGO, YA QUE EL �LTIMO EQUIPO ESTAR� YA EMPAREJADO CON TODOS
        EXIT WHEN v_contador = v_maximo - 1;
            -- EL C�DIGO DEL EQUIPO2 VA A EMPEZAR CON EL DEL EQUIPO1
            v_equipo2.cod_equipo := v_equipo1.cod_equipo;
                -- IREMOS EMPAREJANDO EL EQUIPO1 CON EL RESTO DE EQUIPOS HASTA LLEGAR AL C�DIGO M�XIMO DE EQUIPO
                WHILE v_equipo2.cod_equipo < v_maximo LOOP
                    -- EL C�DIGO DE PARTIDO VA INCREMENTANDO EN UNO
                    v_partido := v_partido + 1;
                    -- EL C�DIGO DEL EQUIPO2 SER� SIEMPRE UNO MAYOR QUE EL ANTERIOR, HASTA LLEGAR AL �LTIMO EQUIPO
                    v_equipo2.cod_equipo := v_equipo2.cod_equipo + 1;
                    -- INSERTAMOS LOS PARTIDOS EN LA TABLA SIN ESPECIFICAR EL RESULTADO, M�S TARDE LO INTRODUCIREMOS
                    INSERT INTO partidos VALUES(v_partido, v_competicion, v_equipo1.cod_equipo, v_equipo2.cod_equipo, '');
                END LOOP;
            -- ESTE CONTADOR NOS PERMITE SALIR DE BUCLE CUANDO HAYAMOS TERMINADO DE GENERAR TODOS LOS PARTIDOS
            v_contador := v_contador + 1;
    END LOOP;
    -- CERRAMOS EL CURSOR
    CLOSE c_equipos;
    -- CONFIRMAMOS LAS FILAS INSERTADAS
    COMMIT;
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE LA COMPETICI�N');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO'); 
END generar_partidos;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.PROCEDIMIENTO QUE RECIBE COMO PAR�METRO EL C�DIGO DE PARTIDO Y EL RESULTADO PARA ACTUALIZAR LA TABLA 'PARTIDOS' CON LOS JUGADOS
CREATE OR REPLACE PROCEDURE reportar_resultados (
    p_partido partidos.cod_partido%TYPE,
    p_resultado partidos.resultado%TYPE) IS
BEGIN
    -- ACTUALIZAMOS LA TABLA 'PARTIDOS' CON EL RESULTADO PASADO POR PAR�METRO
    UPDATE partidos
    SET resultado = p_resultado
    WHERE cod_partido = p_partido;
    -- CONFIRMAMOS LAS FILAS INSERTADAS
    COMMIT;
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE EL PARTIDO');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO'); 
END reportar_resultados;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.PROCEDIMIENTO QUE CREA EL RANKING Y VA SUMANDO LAS V�CTORIAS A TRAV�S DE LA TABLA 'PARTIDOS'
CREATE OR REPLACE PROCEDURE generar_ranking IS
    -- CURSOR EXPL�CITO QUE VA OBTENER TODOS LOS C�DIGOS DE LOS EQUIPOS
    CURSOR c_equipos IS SELECT cod_equipo FROM equipos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_EQUIPOS
    v_equipo c_equipos%ROWTYPE;
    -- CURSOR EXPL�CITO QUE VA OBTENER EL EQUIPO GANADOR DE CADA PARTIDO 
    CURSOR c_resultados IS SELECT resultado FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_RESULTADOS
    v_resultado c_resultados%ROWTYPE;

BEGIN
    -- BORRAMOS TODO LO QUE HUBIESE EN LA TABLA 'RANKING'
    DELETE FROM ranking;
    -- BUCLE QUE VA RECORRIENDO TODOS LOS C�DIGOS DE EQUIPO PARA INTRODUCIRLOS EN LA TABLA 'RANKING', LAS VICTORIAS SE INICIALIZAN A 0
    FOR v_equipo IN c_equipos LOOP
        INSERT INTO ranking VALUES(v_equipo.cod_equipo, 0);
    END LOOP;
    -- BUCLE QUE VA RECORRIENDO TODOS LOS P�RTIDOS Y SUMANDO UNA VICTORIA AL GANADOR EN LA TABLA 'RANKING'
    FOR v_resultado IN c_resultados LOOP
        UPDATE ranking
        SET victorias = victorias + 1
        -- CUANDO EL RESULTADO COINCIDE CON EL C�DIGO DEL EQUIPO DE LA TABLA 'RANKING', SE LE SUMA UNA VICTORIA
        WHERE cod_equipo = v_resultado.resultado;
    END LOOP;
    -- CONFIRMAMOS LAS FILAS INSERTADAS
    COMMIT;
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE EL PARTIDO');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO');
END generar_ranking;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.FUNCI�N QUE RECIBE COMO PAR�METRO LA POSICI�N QUE OCUPA UNA FILA EN LA TABLA 'RANKING' Y DEVUELVE EL C�DIGO DEL EQUIPO SEG�N SUS VICTORIAS
CREATE OR REPLACE FUNCTION obtener_posicion (p_posicion NUMBER) RETURN ranking.cod_equipo%TYPE IS
    -- CURSOR EXPL�CITO QUE ORDENA EL RANKING POR N�MERO DE VICTORIAS Y OBTIENE SU POSICI�N
    CURSOR c_ranking IS SELECT ROW_NUMBER() OVER (ORDER BY victorias desc) AS posicion, cod_equipo FROM ranking;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_RANKING
    v_ranking c_ranking%ROWTYPE;
    -- VARIABLE QUE GUARDA EL C�DIGO DEL EQUIPO
    v_equipo NUMBER(3);
BEGIN
    -- BUCLE QUE RECORRER� TODO EL RANKING HASTA DAR CON LA POSICI�N PASADA POR PAR�METRO
    FOR v_ranking IN c_ranking LOOP
        -- CONDICI�N QUE GUARDAR� EL C�DIGO DEL EQUIPO EN UNA VARIABLE AL ENCONTRAR LA POSICI�N INDICADA POR PAR�METRO
        IF v_ranking.posicion = p_posicion THEN
            -- GUARDAMOS EL C�DIGO DEL EQUIPO EN LA VARIABLE
            v_equipo := v_ranking.cod_equipo;
        END IF;
    END LOOP;
    -- DEVOLVEMOS A LA FUNCI�N EL C�DIGO DEL EQUIPO
    RETURN v_equipo;
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE EL PARTIDO');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO');
END obtener_posicion;
/
--------------------------------------------------------------------------------------------------------------------------------------------
-- 5.FUNCI�N QUE RECIBE COMO PAR�METRO DOS EQUIPOS Y MIRA SU ENFRENTAMIENTO DIRECTO PARA DEVOLVER EL GANADOR, EN CASO DE EMPATE EN VICTORIAS
CREATE OR REPLACE FUNCTION desempatar (
    p_equipo1 equipos.cod_equipo%TYPE,
    p_equipo2 equipos.cod_equipo%TYPE) RETURN equipos.cod_equipo%TYPE IS
    -- CURSOR EXPL�CITO QUE OBTIENE LOS EQUIPOS DE CADA PARTIDO JUNTO AL GANADOR
    CURSOR c_partidos IS SELECT cod_equipo1, cod_equipo2, resultado FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_PARTIDOS
    v_partidos c_partidos%ROWTYPE;
    -- VARIABLE QUE GUARDA EL C�DIGO DEL EQUIPO GANADOR
    v_ganador equipos.cod_equipo%TYPE;
BEGIN
    -- BUCLE QUE RECORRER� TODO LOS PARTIDOS HASTA DAR CON EL PARTIDO DE LOS EQUIPOS PASADO POR PAR�METRO
    FOR v_partidos IN c_partidos LOOP
        -- CONDICI�N QUE GUARDAR� EL GANADOR EN UNA VARIABLE AL ENCONTRAR EL PARTIDO DE LOS EQUIPOS PASADOS POR PAR�METRO
        -- DEBEMOS TENER EN CUENTA QUE LOS C�DIGOS PASADO POR PAR�METRO PUEDEN PERTENECER TANTO AL EQUIPO1 COMO AL EQUIPO2 DE LA TABLA 'PARTIDOS'
        IF (v_partidos.cod_equipo1 = p_equipo1 AND v_partidos.cod_equipo2 = p_equipo2) OR (v_partidos.cod_equipo1 = p_equipo2 AND v_partidos.cod_equipo2 = p_equipo1) THEN
            -- GUARDAMOS AL GANADOR EN LA VARIABLE
            v_ganador := v_partidos.resultado;
        END IF;
    END LOOP;
    -- DEVOLVEMOS A LA FUNCI�N EL C�DIGO DEL EQUIPO GANADOR
    RETURN v_ganador;
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE EL PARTIDO');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO');
END desempatar;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 6.BLOQUE AN�NIMO QUE SER� EL PROGRAMA PRINCIPAL
-- GENERAR� LOS PARTIDOS Y MOSTRAR� EL EQUIPO GANADOR JUNTO SUS JUGADORES
DECLARE
    -- CURSOR EXPL�CITO QUE RECORRE CADA FILA DE LA TABLA 'PARTIDOS'
    CURSOR c_partidos IS SELECT * FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_PARTIDOS
    v_partidos c_partidos%ROWTYPE;
    -- VARIABLE PARA BUSCAR LA COMPETICI�N CON ESE NOMBRE
    v_competicion competiciones.nombre_competicion%TYPE;
    -- CURSOR EXPL�CITO QUE BUSCA EN LOS PARTIDOS GENERADOS EL NOMBRE DE CADA EQUIPO ENFRENTADO
    CURSOR c_enfrentamientos IS 
        SELECT cod_partido, equipo1.nombre_equipo AS equipo1, equipo2.nombre_equipo AS equipo2 , cod_equipo1, cod_equipo2
        FROM partidos, equipos equipo1, equipos equipo2 
        WHERE equipo1.cod_equipo = cod_equipo1 AND equipo2.cod_equipo = cod_equipo2 
        ORDER BY cod_partido;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_ENFRENTAMIENTOS
    v_enfrentamientos c_enfrentamientos%ROWTYPE;
    -- VARIABLE QUE GUARDAR� UN N�MERO ALEATORIO
    v_aleatorio NUMBER(1);
    -- VARIABLES QUE GUARDAN LOS C�DIGOS DE LOS DOS PRIMEROS EQUIPOS DEL RANKING SEG�N SU PUESTO
    v_primero ranking.cod_equipo%TYPE;
    v_segundo ranking.cod_equipo%TYPE;
    -- VARIABLES QUE GUARDAN LAS VICTORIAS DE LOS DOS PRIMEROS EQUIPOS PARA EL DESEMPATE
    v_victorias1 ranking.victorias%TYPE;
    v_victorias2 ranking.victorias%TYPE; 
    -- VARIABLE QUE RECOGER� EL C�DIGO DEL EQUIPO GANADOR
    v_ganador ranking.cod_equipo%TYPE;
    -- VARIABLE QUE GUARDA EL NOMBRE DEL EQUIPO GANADOR
    v_nombre equipos.nombre_equipo%TYPE;
    -- CURSOR EXPL�CITO QUE RECORRE CADA FILA DE LA TABLA 'JUGADORES' SEG�N EL EQUIPO GANADOR PASADO POR PAR�METRO
    CURSOR c_jugadores(p_ganador jugadores.cod_equipo%TYPE) IS SELECT nick FROM jugadores WHERE cod_equipo = p_ganador;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_JUGADORES
    v_jugadores c_jugadores%ROWTYPE; 
BEGIN
    -- PEDIMOS POR TECLADO EN NOMBRE DE LA COMPETICI�N (EN NUESTRO CASO 'RPL MASTER RIFT')
    -- SI INTRODUCIMOS UN NOMBRE QUE NO EXISTA EN LA TABLA 'COMPETICIONES', GENERAR� UNA EXCEPCI�N DEL TIPO 'NO_DATA_FOUND'
    v_competicion := UPPER('&Nombre_Competicion');
    -- 1.GENERAMOS LOS PARTIDOS PARA ESA COMPETICI�N
    generar_partidos (v_competicion);
    -- MOSTRAMOS POR PANTALLA LOS ENFRENTAMIENTOS QUE EXISTEN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ENFRENTAMIENTOS:');
    FOR v_enfrentamientos IN c_enfrentamientos LOOP
       DBMS_OUTPUT.PUT_LINE(v_enfrentamientos.cod_partido ||'. '|| v_enfrentamientos.equipo1 ||' VS. '|| v_enfrentamientos.equipo2); 
    END LOOP;
    
    -- 2.GENERAMOS LOS RESULTADOS DE FORMA ALEATORIA (PARA SIMULAR LOS PARTIDOS) Y LOS INTRODUCIMOS EN CADA ENFRENTAMIENTO
    FOR v_partidos IN c_partidos LOOP
    -- GENERAMOS UN N�MERO ALEATORIO ENTRE 1 y 2, SI SALE 1 GANA EL EQUIPO1 Y SI SALE 2 GANA EL EQUIPO2
        SELECT ROUND(DBMS_RANDOM.VALUE(1,2)) INTO v_aleatorio FROM dual;
        IF v_aleatorio = 1 THEN
            reportar_resultados(v_partidos.cod_partido, v_partidos.cod_equipo1);
        ELSE
            reportar_resultados(v_partidos.cod_partido, v_partidos.cod_equipo2);
        END IF;
    END LOOP;
    
    -- 3.GENERAMOS EL RANKING
    generar_ranking;
    
    -- 4.OBTENEMOS LOS C�DIGOS DE LOS DOS PRIMEROS EQUIPOS DEL RANKING Y LO GUARDAMOS EN VARIABLES
    SELECT obtener_posicion(1) INTO v_primero FROM DUAL;
    SELECT obtener_posicion(2) INTO v_segundo FROM DUAL;
    -- GUARDAMOS EN LAS VARIABLES LAS VICTORIAS DE LOS 2 PRIMEROS EQUIPOS
    SELECT victorias INTO v_victorias1 FROM ranking WHERE cod_equipo = v_primero;
    SELECT victorias INTO v_victorias2 FROM ranking WHERE cod_equipo = v_segundo;
    
    -- 5.SI HAY EMPATES, MIRAREMOS SUS ENFRENTAMIENTOS DIRECTOS
    IF v_victorias1 = v_victorias2 THEN
        -- SI SON IGUALES LAS VICTORIAS, SE EJECUTAR� LA FUNCI�N PARA OBTENER EL GANADOR
        SELECT desempatar(v_primero, v_segundo) INTO v_ganador FROM dual;
    ELSE
        -- SI NO SON IGUALES LAS VICTORIAS, EL EQUIPO QUE APARECE EL PRIMERO TENDR� MAS VICTORIAS
        v_ganador := v_primero;
    END IF;
    
    -- MOSTRAMOS POR PANTALLA EL EQUIPO GANADOR
    SELECT nombre_equipo INTO v_nombre FROM equipos WHERE cod_equipo = v_ganador;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('EL EQUIPO GANADOR DE LA COMPETICI�N ES: ' ||  v_nombre);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('JUGADORES:');
    -- BUCLE QUE MOSTRAR� EL NICK DE CADA JUGADOR DEL EQUIPO GANADOR
    FOR v_jugadores IN c_jugadores(v_ganador) LOOP
        DBMS_OUTPUT.PUT_LINE(v_jugadores.nick);
    END LOOP; 
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE LA COMPETICI�N');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO'); 
END;
/
--------------------------------------------------------------------------------------------------------------------------------------------------