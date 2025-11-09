-- ЛАБА 1
-- Включаем SCRAM
ALTER SYSTEM SET password_encryption = 'scram-sha-256';
SELECT pg_reload_conf();

--Создадим роли
CREATE ROLE app_reader NOLOGIN; -- Чтение данных приложения
CREATE ROLE app_writer NOLOGIN; -- Чтение/запись данных приложения
CREATE ROLE app_owner NOLOGIN; -- Владелец приложения (может изменять структуру)
CREATE ROLE auditor NOLOGIN; -- Роль для аудита
CREATE ROLE ddl_admin NOLOGIN; -- Может делать только DDL (создание/изменение таблиц, схем)
CREATE ROLE dml_admin NOLOGIN; -- Может делать только DML (INSERT/UPDATE/DELETE)
CREATE ROLE security_admin NOLOGIN; -- Администрирование безопасности: GRANT/REVOKE

-- логины с минимумом прав и NOINHERIT
CREATE ROLE u_reader LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_writer LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_owner LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_auditor LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_ddl_admin LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_dml_admin LOGIN NOINHERIT PASSWORD 'banana';
CREATE ROLE u_security_admin LOGIN NOINHERIT PASSWORD 'banana';


CREATE ROLE stat_user_1 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_2 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_3 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_4 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_5 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_6 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_7 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_8 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_9 LOGIN INHERIT PASSWORD 'banana';
CREATE ROLE stat_user_10 LOGIN INHERIT PASSWORD 'banana';


GRANT app_reader TO u_reader;
GRANT app_writer TO u_writer;
GRANT app_owner TO u_owner;
GRANT auditor TO u_auditor;
GRANT ddl_admin TO u_ddl_admin;
GRANT dml_admin TO u_dml_admin;
GRANT security_admin TO u_security_admin;

--Создаем схемы
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION app_owner;
CREATE SCHEMA IF NOT EXISTS ref AUTHORIZATION app_owner;
CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION app_owner;
CREATE SCHEMA IF NOT EXISTS stg AUTHORIZATION app_owner;

GRANT CONNECT ON DATABASE firestation TO u_reader, u_writer, u_owner, u_auditor, u_ddl_admin, u_dml_admin, u_security_admin;
GRANT CONNECT ON DATABASE firestation TO stat_user_1, stat_user_2, stat_user_3, stat_user_4, stat_user_5, stat_user_6, stat_user_7, stat_user_8, stat_user_9, stat_user_10; 
GRANT USAGE ON SCHEMA app TO app_reader, app_writer, app_owner;
GRANT USAGE ON SCHEMA ref TO app_reader, app_writer, app_owner;
GRANT USAGE ON SCHEMA audit TO auditor;

-- Даем право создавать объекты в схемах приложения
GRANT CREATE ON SCHEMA app TO ddl_admin;
GRANT CREATE ON SCHEMA ref TO ddl_admin;
GRANT CREATE ON SCHEMA stg TO ddl_admin;
GRANT CREATE ON SCHEMA audit TO ddl_admin;

-- Чтобы мог изменять структуру существующих объектов
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO ddl_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ref TO ddl_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stg TO ddl_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO ddl_admin;

-- Запрет на DML
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app, ref, stg, audit FROM ddl_admin;

-- Доступ к данным для DML
GRANT USAGE ON SCHEMA app TO dml_admin;
GRANT USAGE ON SCHEMA ref TO dml_admin;
GRANT USAGE ON SCHEMA audit TO dml_admin;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO dml_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ref TO dml_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA stg TO dml_admin;

-- Чтобы мог работать с последовательностями
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA app TO dml_admin;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ref TO dml_admin;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA stg TO dml_admin;

-- Запрет на DDL
REVOKE CREATE ON SCHEMA app, ref, stg, audit FROM dml_admin;


-- Даем право управлять ролями
ALTER ROLE security_admin CREATEROLE;

GRANT app_owner TO security_admin;

-- Запрет на доступ к данным
REVOKE SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app, ref, stg, audit FROM security_admin;


-- Запрещаем PUBLIC доступ
REVOKE ALL ON SCHEMA app FROM PUBLIC;
REVOKE ALL ON SCHEMA ref FROM PUBLIC;
REVOKE ALL ON SCHEMA audit FROM PUBLIC;
REVOKE ALL ON SCHEMA stg FROM PUBLIC;
REVOKE CONNECT ON DATABASE firestation FROM PUBLIC;
REVOKE CREATE, USAGE ON SCHEMA public FROM PUBLIC;

-- Назначаем владельца схемы app
ALTER SCHEMA app OWNER TO app_owner;
ALTER SCHEMA ref OWNER TO app_owner;
ALTER SCHEMA audit OWNER TO app_owner;
ALTER SCHEMA stg OWNER TO app_owner;

-- Для владельца — все права
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_owner;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_owner;

-- Чтение для всех, запись только владельцу
GRANT USAGE ON SCHEMA app TO app_reader, app_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_reader;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA app TO app_writer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO app_owner;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_owner;

GRANT USAGE ON SCHEMA ref TO app_reader, app_writer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ref TO app_reader;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ref TO app_writer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ref TO app_owner;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ref TO app_owner;


-- Только чтение auditor
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO auditor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA audit TO auditor;

-- Запрет для всех остальных
REVOKE ALL ON ALL TABLES IN SCHEMA audit FROM PUBLIC, app_reader, app_writer;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA app
    GRANT SELECT ON TABLES TO app_reader;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA ref
    GRANT SELECT ON TABLES TO app_reader;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA app
    GRANT SELECT, UPDATE, INSERT ON TABLES TO app_writer;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA ref
    GRANT SELECT, UPDATE, INSERT ON TABLES TO app_writer;

-- Для будущих последовательностей
ALTER DEFAULT PRIVILEGES 
    FOR ROLE app_owner IN SCHEMA app
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_writer;

ALTER DEFAULT PRIVILEGES 
    FOR ROLE app_owner IN SCHEMA ref
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app_writer;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA app
    GRANT USAGE, SELECT ON SEQUENCES TO app_reader;

ALTER DEFAULT PRIVILEGES
    FOR ROLE app_owner IN SCHEMA ref
    GRANT USAGE, SELECT ON SEQUENCES TO app_reader;

SET ROLE app_owner;
