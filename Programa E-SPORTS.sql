-- PROGRAMA E-SPORTS
--ALBERTO GARCÍA NAVARRO 1ºCFGS DAW

-- PROGRAMA QUE GENERARÁ LOS PARTIDOS DE UNA COMPETICIÓN DE FORMA AUTOMÁTICA Y MOSTRARÁ EL EQUIPO GANADOR Y SUS JUGADORES

-- SENTENCIA PARA QUE SE MUESTRE CORRECTAMENTE LOS DATOS POR PANTALLA
SET SERVEROUTPUT ON;
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.PROCEDIMIENTO QUE RECIBE COMO PARÁMETRO UNA COMPETICIÓN Y GENERAMOS LOS PARTIDOS QUE SE VAN A JUGAR CON LOS EQUIPOS QUE HAY EN LA TABLA 'EQUIPOS'
CREATE OR REPLACE PROCEDURE generar_partidos (p_competicion competiciones.nombre_competicion%TYPE) IS
    -- CURSOR EXPLÍCITO QUE VA OBTENER TODOS LOS CÓDIGOS DE LOS EQUIPOS
    CURSOR c_equipos IS SELECT cod_equipo FROM equipos;
    -- VARIABLES QUE GUARDAN LOS REGISTROS DE C_EQUIPOS
    v_equipo1 c_equipos%ROWTYPE;
    v_equipo2 c_equipos%ROWTYPE;
    -- EL CÓDIGO MÁXIMO QUE HAY EN LA TABLA 'EQUIPOS'
    v_maximo equipos.cod_equipo%TYPE := 0;
    -- VARIABLE QUE GENERARÁ LOS CÓDIGOS DE LOS PARTIDOS DE FORMA CONSECUTIVA
    v_partido NUMBER(3) := 0;
    -- VARIABLE QUE GUARDA EL CÓDIGO DE COMPETICIÓN
    v_competicion competiciones.cod_competicion%TYPE;
    -- CONTADOR PARA LLEVAR EL BUCLE DE GENERAR PARTIDOS
    v_contador NUMBER(3) := 0;
BEGIN
    -- BORRAMOS TODO LO QUE HUBIESE EN LA TABLA 'PARTIDOS'
    DELETE FROM partidos;
    -- CURSOR IMPLÍCITO PARA GUARDAR EN UNA VARIABLE EL CÓDIGO DE LA COMPETICIÓN PASADA POR PARÁMETRO
    SELECT cod_competicion INTO v_competicion FROM competiciones WHERE UPPER(nombre_competicion) = UPPER(p_competicion);
    -- CURSOR IMPLÍCITO QUE GUARDA EN UNA VARIABLE EL ÚLTIMO CÓDIGO DEL EQUIPO DE LA TABLA 'EQUIPOS'
    SELECT MAX(cod_equipo) INTO v_maximo FROM EQUIPOS;
    -- BUCLE QUE VA GENERANDO CADA PARTIDO
    OPEN c_equipos;
    LOOP
        -- GUARDAMOS EN UNA VARIABLE EL CÓDIGO DEL PRIMER EQUIPO
        FETCH c_equipos INTO v_equipo1;
        -- EL BUCLE ACABARÁ AL LLEGAR AL PENÚLTIMO CÓDIGO, YA QUE EL ÚLTIMO EQUIPO ESTARÁ YA EMPAREJADO CON TODOS
        EXIT WHEN v_contador = v_maximo - 1;
            -- EL CÓDIGO DEL EQUIPO2 VA A EMPEZAR CON EL DEL EQUIPO1
            v_equipo2.cod_equipo := v_equipo1.cod_equipo;
                -- IREMOS EMPAREJANDO EL EQUIPO1 CON EL RESTO DE EQUIPOS HASTA LLEGAR AL CÓDIGO MÁXIMO DE EQUIPO
                WHILE v_equipo2.cod_equipo < v_maximo LOOP
                    -- EL CÓDIGO DE PARTIDO VA INCREMENTANDO EN UNO
                    v_partido := v_partido + 1;
                    -- EL CÓDIGO DEL EQUIPO2 SERÁ SIEMPRE UNO MAYOR QUE EL ANTERIOR, HASTA LLEGAR AL ÚLTIMO EQUIPO
                    v_equipo2.cod_equipo := v_equipo2.cod_equipo + 1;
                    -- INSERTAMOS LOS PARTIDOS EN LA TABLA SIN ESPECIFICAR EL RESULTADO, MÁS TARDE LO INTRODUCIREMOS
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
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE LA COMPETICIÓN');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO'); 
END generar_partidos;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.PROCEDIMIENTO QUE RECIBE COMO PARÁMETRO EL CÓDIGO DE PARTIDO Y EL RESULTADO PARA ACTUALIZAR LA TABLA 'PARTIDOS' CON LOS JUGADOS
CREATE OR REPLACE PROCEDURE reportar_resultados (
    p_partido partidos.cod_partido%TYPE,
    p_resultado partidos.resultado%TYPE) IS
BEGIN
    -- ACTUALIZAMOS LA TABLA 'PARTIDOS' CON EL RESULTADO PASADO POR PARÁMETRO
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
-- 3.PROCEDIMIENTO QUE CREA EL RANKING Y VA SUMANDO LAS VÍCTORIAS A TRAVÉS DE LA TABLA 'PARTIDOS'
CREATE OR REPLACE PROCEDURE generar_ranking IS
    -- CURSOR EXPLÍCITO QUE VA OBTENER TODOS LOS CÓDIGOS DE LOS EQUIPOS
    CURSOR c_equipos IS SELECT cod_equipo FROM equipos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_EQUIPOS
    v_equipo c_equipos%ROWTYPE;
    -- CURSOR EXPLÍCITO QUE VA OBTENER EL EQUIPO GANADOR DE CADA PARTIDO 
    CURSOR c_resultados IS SELECT resultado FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_RESULTADOS
    v_resultado c_resultados%ROWTYPE;

BEGIN
    -- BORRAMOS TODO LO QUE HUBIESE EN LA TABLA 'RANKING'
    DELETE FROM ranking;
    -- BUCLE QUE VA RECORRIENDO TODOS LOS CÓDIGOS DE EQUIPO PARA INTRODUCIRLOS EN LA TABLA 'RANKING', LAS VICTORIAS SE INICIALIZAN A 0
    FOR v_equipo IN c_equipos LOOP
        INSERT INTO ranking VALUES(v_equipo.cod_equipo, 0);
    END LOOP;
    -- BUCLE QUE VA RECORRIENDO TODOS LOS PÁRTIDOS Y SUMANDO UNA VICTORIA AL GANADOR EN LA TABLA 'RANKING'
    FOR v_resultado IN c_resultados LOOP
        UPDATE ranking
        SET victorias = victorias + 1
        -- CUANDO EL RESULTADO COINCIDE CON EL CÓDIGO DEL EQUIPO DE LA TABLA 'RANKING', SE LE SUMA UNA VICTORIA
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
-- 4.FUNCIÓN QUE RECIBE COMO PARÁMETRO LA POSICIÓN QUE OCUPA UNA FILA EN LA TABLA 'RANKING' Y DEVUELVE EL CÓDIGO DEL EQUIPO SEGÚN SUS VICTORIAS
CREATE OR REPLACE FUNCTION obtener_posicion (p_posicion NUMBER) RETURN ranking.cod_equipo%TYPE IS
    -- CURSOR EXPLÍCITO QUE ORDENA EL RANKING POR NÚMERO DE VICTORIAS Y OBTIENE SU POSICIÓN
    CURSOR c_ranking IS SELECT ROW_NUMBER() OVER (ORDER BY victorias desc) AS posicion, cod_equipo FROM ranking;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_RANKING
    v_ranking c_ranking%ROWTYPE;
    -- VARIABLE QUE GUARDA EL CÓDIGO DEL EQUIPO
    v_equipo NUMBER(3);
BEGIN
    -- BUCLE QUE RECORRERÁ TODO EL RANKING HASTA DAR CON LA POSICIÓN PASADA POR PARÁMETRO
    FOR v_ranking IN c_ranking LOOP
        -- CONDICIÓN QUE GUARDARÁ EL CÓDIGO DEL EQUIPO EN UNA VARIABLE AL ENCONTRAR LA POSICIÓN INDICADA POR PARÁMETRO
        IF v_ranking.posicion = p_posicion THEN
            -- GUARDAMOS EL CÓDIGO DEL EQUIPO EN LA VARIABLE
            v_equipo := v_ranking.cod_equipo;
        END IF;
    END LOOP;
    -- DEVOLVEMOS A LA FUNCIÓN EL CÓDIGO DEL EQUIPO
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
-- 5.FUNCIÓN QUE RECIBE COMO PARÁMETRO DOS EQUIPOS Y MIRA SU ENFRENTAMIENTO DIRECTO PARA DEVOLVER EL GANADOR, EN CASO DE EMPATE EN VICTORIAS
CREATE OR REPLACE FUNCTION desempatar (
    p_equipo1 equipos.cod_equipo%TYPE,
    p_equipo2 equipos.cod_equipo%TYPE) RETURN equipos.cod_equipo%TYPE IS
    -- CURSOR EXPLÍCITO QUE OBTIENE LOS EQUIPOS DE CADA PARTIDO JUNTO AL GANADOR
    CURSOR c_partidos IS SELECT cod_equipo1, cod_equipo2, resultado FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DE C_PARTIDOS
    v_partidos c_partidos%ROWTYPE;
    -- VARIABLE QUE GUARDA EL CÓDIGO DEL EQUIPO GANADOR
    v_ganador equipos.cod_equipo%TYPE;
BEGIN
    -- BUCLE QUE RECORRERÁ TODO LOS PARTIDOS HASTA DAR CON EL PARTIDO DE LOS EQUIPOS PASADO POR PARÁMETRO
    FOR v_partidos IN c_partidos LOOP
        -- CONDICIÓN QUE GUARDARÁ EL GANADOR EN UNA VARIABLE AL ENCONTRAR EL PARTIDO DE LOS EQUIPOS PASADOS POR PARÁMETRO
        -- DEBEMOS TENER EN CUENTA QUE LOS CÓDIGOS PASADO POR PARÁMETRO PUEDEN PERTENECER TANTO AL EQUIPO1 COMO AL EQUIPO2 DE LA TABLA 'PARTIDOS'
        IF (v_partidos.cod_equipo1 = p_equipo1 AND v_partidos.cod_equipo2 = p_equipo2) OR (v_partidos.cod_equipo1 = p_equipo2 AND v_partidos.cod_equipo2 = p_equipo1) THEN
            -- GUARDAMOS AL GANADOR EN LA VARIABLE
            v_ganador := v_partidos.resultado;
        END IF;
    END LOOP;
    -- DEVOLVEMOS A LA FUNCIÓN EL CÓDIGO DEL EQUIPO GANADOR
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
-- 6.BLOQUE ANÓNIMO QUE SERÁ EL PROGRAMA PRINCIPAL
-- GENERARÁ LOS PARTIDOS Y MOSTRARÁ EL EQUIPO GANADOR JUNTO SUS JUGADORES
DECLARE
    -- CURSOR EXPLÍCITO QUE RECORRE CADA FILA DE LA TABLA 'PARTIDOS'
    CURSOR c_partidos IS SELECT * FROM partidos;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_PARTIDOS
    v_partidos c_partidos%ROWTYPE;
    -- VARIABLE PARA BUSCAR LA COMPETICIÓN CON ESE NOMBRE
    v_competicion competiciones.nombre_competicion%TYPE;
    -- CURSOR EXPLÍCITO QUE BUSCA EN LOS PARTIDOS GENERADOS EL NOMBRE DE CADA EQUIPO ENFRENTADO
    CURSOR c_enfrentamientos IS 
        SELECT cod_partido, equipo1.nombre_equipo AS equipo1, equipo2.nombre_equipo AS equipo2 , cod_equipo1, cod_equipo2
        FROM partidos, equipos equipo1, equipos equipo2 
        WHERE equipo1.cod_equipo = cod_equipo1 AND equipo2.cod_equipo = cod_equipo2 
        ORDER BY cod_partido;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_ENFRENTAMIENTOS
    v_enfrentamientos c_enfrentamientos%ROWTYPE;
    -- VARIABLE QUE GUARDARÁ UN NÚMERO ALEATORIO
    v_aleatorio NUMBER(1);
    -- VARIABLES QUE GUARDAN LOS CÓDIGOS DE LOS DOS PRIMEROS EQUIPOS DEL RANKING SEGÚN SU PUESTO
    v_primero ranking.cod_equipo%TYPE;
    v_segundo ranking.cod_equipo%TYPE;
    -- VARIABLES QUE GUARDAN LAS VICTORIAS DE LOS DOS PRIMEROS EQUIPOS PARA EL DESEMPATE
    v_victorias1 ranking.victorias%TYPE;
    v_victorias2 ranking.victorias%TYPE; 
    -- VARIABLE QUE RECOGERÁ EL CÓDIGO DEL EQUIPO GANADOR
    v_ganador ranking.cod_equipo%TYPE;
    -- VARIABLE QUE GUARDA EL NOMBRE DEL EQUIPO GANADOR
    v_nombre equipos.nombre_equipo%TYPE;
    -- CURSOR EXPLÍCITO QUE RECORRE CADA FILA DE LA TABLA 'JUGADORES' SEGÚN EL EQUIPO GANADOR PASADO POR PARÁMETRO
    CURSOR c_jugadores(p_ganador jugadores.cod_equipo%TYPE) IS SELECT nick FROM jugadores WHERE cod_equipo = p_ganador;
    -- VARIABLE QUE GUARDA LOS REGISTROS DEL CURSOR C_JUGADORES
    v_jugadores c_jugadores%ROWTYPE; 
BEGIN
    -- PEDIMOS POR TECLADO EN NOMBRE DE LA COMPETICIÓN (EN NUESTRO CASO 'RPL MASTER RIFT')
    -- SI INTRODUCIMOS UN NOMBRE QUE NO EXISTA EN LA TABLA 'COMPETICIONES', GENERARÁ UNA EXCEPCIÓN DEL TIPO 'NO_DATA_FOUND'
    v_competicion := UPPER('&Nombre_Competicion');
    -- 1.GENERAMOS LOS PARTIDOS PARA ESA COMPETICIÓN
    generar_partidos (v_competicion);
    -- MOSTRAMOS POR PANTALLA LOS ENFRENTAMIENTOS QUE EXISTEN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('ENFRENTAMIENTOS:');
    FOR v_enfrentamientos IN c_enfrentamientos LOOP
       DBMS_OUTPUT.PUT_LINE(v_enfrentamientos.cod_partido ||'. '|| v_enfrentamientos.equipo1 ||' VS. '|| v_enfrentamientos.equipo2); 
    END LOOP;
    
    -- 2.GENERAMOS LOS RESULTADOS DE FORMA ALEATORIA (PARA SIMULAR LOS PARTIDOS) Y LOS INTRODUCIMOS EN CADA ENFRENTAMIENTO
    FOR v_partidos IN c_partidos LOOP
    -- GENERAMOS UN NÚMERO ALEATORIO ENTRE 1 y 2, SI SALE 1 GANA EL EQUIPO1 Y SI SALE 2 GANA EL EQUIPO2
        SELECT ROUND(DBMS_RANDOM.VALUE(1,2)) INTO v_aleatorio FROM dual;
        IF v_aleatorio = 1 THEN
            reportar_resultados(v_partidos.cod_partido, v_partidos.cod_equipo1);
        ELSE
            reportar_resultados(v_partidos.cod_partido, v_partidos.cod_equipo2);
        END IF;
    END LOOP;
    
    -- 3.GENERAMOS EL RANKING
    generar_ranking;
    
    -- 4.OBTENEMOS LOS CÓDIGOS DE LOS DOS PRIMEROS EQUIPOS DEL RANKING Y LO GUARDAMOS EN VARIABLES
    SELECT obtener_posicion(1) INTO v_primero FROM DUAL;
    SELECT obtener_posicion(2) INTO v_segundo FROM DUAL;
    -- GUARDAMOS EN LAS VARIABLES LAS VICTORIAS DE LOS DOS PRIMEROS EQUIPOS
    SELECT victorias INTO v_victorias1 FROM ranking WHERE cod_equipo = v_primero;
    SELECT victorias INTO v_victorias2 FROM ranking WHERE cod_equipo = v_segundo;
    
    -- 5.SI HAY EMPATES, MIRAREMOS SUS ENFRENTAMIENTOS DIRECTOS
    IF v_victorias1 = v_victorias2 THEN
        -- SI SON IGUALES LAS VICTORIAS, SE EJECUTARÁ LA FUNCIÓN PARA OBTENER EL GANADOR
        SELECT desempatar(v_primero, v_segundo) INTO v_ganador FROM dual;
    ELSE
        -- SI NO SON IGUALES LAS VICTORIAS, EL EQUIPO QUE APARECE EL PRIMERO TENDRÁ MAS VICTORIAS
        v_ganador := v_primero;
    END IF;
    
    -- MOSTRAMOS POR PANTALLA EL EQUIPO GANADOR
    SELECT nombre_equipo INTO v_nombre FROM equipos WHERE cod_equipo = v_ganador;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('EL EQUIPO GANADOR DE LA COMPETICIÓN ES: ' ||  v_nombre);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('JUGADORES:');
    -- BUCLE QUE MOSTRARÁ EL NICK DE CADA JUGADOR DEL EQUIPO GANADOR
    FOR v_jugadores IN c_jugadores(v_ganador) LOOP
        DBMS_OUTPUT.PUT_LINE(v_jugadores.nick);
    END LOOP; 
-- GESTIONAMOS LAS POSIBLES EXCEPCIONES
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: NO EXISTE LA COMPETICIÓN');
    WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO'); 
END;
/
--------------------------------------------------------------------------------------------------------------------------------------------------
