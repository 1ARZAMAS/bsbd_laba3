SET ROLE fireadmin;

-- Таблица с логами
CREATE TABLE audit.login_log
(
    log_id SERIAL PRIMARY KEY,
    login_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    username TEXT NOT NULL,
    client_ip INET
);

-- Создаем функцию добавления даты логина, ника и айпи в логи при подключении к бд
CREATE OR REPLACE FUNCTION audit.log_connection()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO audit.login_log(username, client_ip)
    VALUES (session_user, inet_client_addr());
END;
$$;

CREATE EVENT TRIGGER login_trigger ON login
    EXECUTE FUNCTION audit.log_connection();

ALTER FUNCTION audit.log_connection()
    SET search_path = 'audit';

-- security_admin может менять SECURITY DEFINER функции
GRANT EXECUTE ON FUNCTION audit.log_connection() TO security_admin;

GRANT SELECT ON TABLE audit.login_log TO auditor;