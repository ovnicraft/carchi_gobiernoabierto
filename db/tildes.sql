CREATE OR REPLACE FUNCTION tildes(varchar) RETURNS VARCHAR AS '

    DECLARE
        v_string alias for $1;
        p_string varchar;
        BEGIN
            SELECT INTO p_string translate(v_string, ''áàâéèêëìíîòóôúùûüñçÁÀÂÉÈÊËÌÍÎÒÓÔÚÙÛÜÑÇ¿ºª'',''aaaeeeeiiiooouuuuncAAAEEEEIIIOOOUUUUNC?oa'');
            RETURN p_string;
        END;

' LANGUAGE 'plpgsql';
