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

--Создаем сами таблицы
CREATE TABLE ref.roles
(
    role_id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE
);

CREATE TABLE ref.firefighter_ranks (
    rank_id SERIAL PRIMARY KEY,
    rank VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE ref.vehicle_statuses (
    status_id SERIAL PRIMARY KEY,
    status VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE ref.vehicle_types (
    type_id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE app.stations
(
    station_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(11)
);

CREATE TABLE app.firefighters
(
    firefighter_id SERIAL PRIMARY KEY,
    station_id INTEGER NOT NULL REFERENCES app.stations(station_id) ON DELETE RESTRICT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    rank_id INTEGER REFERENCES ref.firefighter_ranks(rank_id) ON DELETE SET NULL,
    phone VARCHAR(11) UNIQUE,
    email VARCHAR(50) UNIQUE,
    hire_date DATE
);

CREATE TABLE app.vehicles
(
    vehicle_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    type_id INTEGER REFERENCES ref.vehicle_types(type_id) ON DELETE SET NULL,
    model VARCHAR(100),
    plate_number VARCHAR(50) UNIQUE,
    status_id INTEGER REFERENCES ref.vehicle_statuses(status_id) ON DELETE SET NULL,
    last_inspected DATE
);

CREATE TABLE app.equipment
(
    equipment_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    name VARCHAR(50),
    sku VARCHAR(50),
    quantity INTEGER DEFAULT 1 CHECK (quantity >= 0),
    condition VARCHAR(50) DEFAULT 'good' CHECK (condition IN ('good', 'serviceable', 'needs_repair', 'broken')),
    last_inspected DATE
);

CREATE TABLE app.incidents
(
    incident_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    incident_type VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('critical', 'high', 'normal', 'medium', 'low')),
    location TEXT,
    reported_at TIMESTAMP WITH TIME ZONE,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    cleared_at TIMESTAMP WITH TIME ZONE,
    description TEXT
);

CREATE TABLE app.responses
(
    response_id SERIAL PRIMARY KEY,
    incident_id INTEGER NOT NULL REFERENCES app.incidents(incident_id) ON DELETE CASCADE,
    vehicle_id INTEGER REFERENCES app.vehicles(vehicle_id) ON DELETE SET NULL,
    firefighter_id INTEGER NOT NULL REFERENCES app.firefighters(firefighter_id) ON DELETE SET NULL,
    role_id INTEGER REFERENCES ref.roles(role_id) ON DELETE SET NULL,
    assigned_at TIMESTAMP WITH TIME ZONE,
    arrived_at TIMESTAMP WITH TIME ZONE,
    cleared_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE app.shifts
(
    shift_id SERIAL PRIMARY KEY,
    firefighter_id INTEGER REFERENCES app.firefighters(firefighter_id) ON DELETE CASCADE,
    station_id INTEGER NOT NULL REFERENCES app.stations(station_id) ON DELETE RESTRICT,
    shift_date DATE,
    notes TEXT,
    CONSTRAINT uq_shift_unique UNIQUE(firefighter_id, shift_date)
);


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

-- Комментарии 
COMMENT ON TABLE app.stations IS 'Таблица пожарных станций';
COMMENT ON TABLE app.firefighters IS 'Таблица сотрудников пожарной станции содержит чувствительные данные';
COMMENT ON TABLE app.vehicles IS 'Таблица пожарной техники';
COMMENT ON TABLE app.equipment IS 'Таблица оборудования и инвентаря';
COMMENT ON TABLE app.incidents IS 'Таблица инцидентов содержит чувствительные данные';
COMMENT ON TABLE ref.roles IS 'Справочник ролей пожарных на вызове';
COMMENT ON TABLE app.responses IS 'Таблица участия сотрудников и техники в инцидентах';
COMMENT ON TABLE app.shifts IS 'Таблица смен сотрудников';
COMMENT ON TABLE ref.vehicle_statuses IS 'Справочник статусов транспортных средств';
COMMENT ON TABLE ref.vehicle_types IS 'Справочник типов транспортных средств';
COMMENT ON TABLE ref.firefighter_ranks IS 'Справочник званий пожарных';

-- ==================== RANKS ====================
INSERT INTO ref.firefighter_ranks(rank) VALUES
('Пожарный'),
('Старший пожарный'),
('Младший сержант'),
('Сержант'),
('Старший сержант'),
('Прапорщик'),
('Старший прапорщик'),
('Лейтенант'),
('Старший лейтенант'),
('Капитан');

-- ==================== VEHICLE STATUSES ====================
INSERT INTO ref.vehicle_statuses(status) VALUES
('available'),
('in_service'),
('out_of_service'),
('maintenance'),
('reserved'),
('standby'),
('decommissioned'),
('awaiting_parts'),
('training_only'),
('unknown');

-- ==================== VEHICLE TYPES  ====================
INSERT INTO ref.vehicle_types(type) VALUES
('Автоцистерна'),
('Автолестница'),
('Спасательный'),
('Штабной'),
('Аварийно-спасательный'),
('Автоколенч. подъёмник'),
('Автолаборатория'),
('Насосно-рукавный автомобиль'),
('Автомобиль дымоудаления'),
('Мотопомпы');

-- ==================== ROLES ====================
INSERT INTO ref.roles(name)
VALUES
('Водитель'),
('Экипаж'),
('Начальник вызова'),
('Парамедик'),
('Инспектор безопасности'),
('Диспетчер'),
('Инженер'),
('Наблюдатель'),
('Инструктор'),
('Медик');

-- ==================== STATIONS ====================
INSERT INTO app.stations(name, address, phone)
VALUES
('Пожарная часть №1', 'ул. Октябрьская, 86, Новосибирск', '83832237970'),
('Пожарная часть №2', 'ул. Карпатская, 1, Новосибирск', '83832744613'),
('Пожарная часть №3', 'ул. Кирова, 130, Новосибирск', '83832665117'),
('Пожарная часть №4', 'ул. Комбинатская, 8, Новосибирск', '83832790101'),
('Пожарная часть №5', 'ул. Вавилова, 1а, Новосибирск', '83832260452'),
('Пожарная часть №6', 'ул. Широкая, 38, Новосибирск', '83833415221'),
('Пожарная часть №7', 'ул. Эйхе, 9, Новосибирск', '83832665117'),
('Пожарная часть №8', 'ул. Кутателадзе, 3, Новосибирск', '83833320748'),
('Пожарная часть №9', 'ул. Сибиряков-Гвардейцев, 52, Новосибирск', '83833535031'),
('Пожарная часть №10', 'ул. Чекалина, 13а, Новосибирск', '83832747680');

-- ==================== FIREFIGHTERS ====================
INSERT INTO app.firefighters(station_id, first_name, last_name, rank_id, phone, email, hire_date)
VALUES
(1,'Иван','Иванов',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Капитан'),'89130000001','ivan.ivanov@nsfire.ru','2015-01-10'),
(1,'Александра','Смирнова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Лейтенант'),'89130000002','alexandra.smirnova@nsfire.ru','2016-02-15'),
(2,'Борис','Петров',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Пожарный'),'89130000003','boris.petrov@nsfire.ru','2017-03-20'),
(2,'Карина','Васильева',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Пожарный'),'89130000004','karina.vasilieva@nsfire.ru','2018-04-25'),
(3,'Дмитрий','Сидоров',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Лейтенант'),'89130000005','dmitry.sidorov@nsfire.ru','2019-05-30'),
(3,'Елена','Кузнецова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Капитан'),'89130000006','elena.kuznetsova@nsfire.ru','2020-06-10'),
(4,'Фёдор','Морозов',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Старший пожарный'),'89130000007','fedor.morozov@nsfire.ru','2016-07-15'),
(4,'Галина','Волкова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Сержант'),'89130000008','galina.volkova@nsfire.ru','2017-08-20'),
(5,'Геннадий','Новиков',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Старший лейтенант'),'89130000009','gennadiy.novikov@nsfire.ru','2018-09-25'),
(5,'Ирина','Тарасова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Младший сержант'),'89130000010','irina.tarasova@nsfire.ru','2019-10-30');

-- ==================== VEHICLES ====================
INSERT INTO app.vehicles(station_id,type_id,model,plate_number,status_id,last_inspected)
VALUES
(1, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'), 'AC-1000','НС01-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),     '2025-01-01'),
(1, (SELECT type_id FROM ref.vehicle_types WHERE type='Автолестница'), 'AL-500','НС01-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),    '2025-01-05'),
(2, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'), 'RS-300','НС02-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),     '2025-02-01'),
(2, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'), 'AC-1200','НС02-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='out_of_service'),'2025-02-05'),
(3, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'), 'AC-1100','НС03-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),     '2025-03-01'),
(3, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'), 'RS-350','НС03-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),    '2025-03-05'),
(4, (SELECT type_id FROM ref.vehicle_types WHERE type='Автолестница'), 'AL-600','НС04-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),     '2025-04-01'),
(4, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'), 'AC-1300','НС04-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),     '2025-04-05'),
(5, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'), 'RS-400','НС05-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),    '2025-05-01'),
(5, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'), 'AC-1400','НС05-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='out_of_service'),'2025-05-05');

-- ==================== INCIDENTS ====================
INSERT INTO app.incidents(station_id, incident_type, priority, location, reported_at, dispatched_at, cleared_at, description)
VALUES
(1,'Пожар','high','ул. Красный проспект, д. 10','2025-09-01 10:00','2025-09-01 10:05','2025-09-01 11:00','Пожар в квартире'),
(2,'Медицинский','medium','ул. Дуси Ковальчук, д. 50','2025-09-02 11:00','2025-09-02 11:05','2025-09-02 11:45','Сердечный приступ'),
(3,'Ложная тревога','low','ул. Сибирская, д. 80','2025-09-03 12:00','2025-09-03 12:10','2025-09-03 12:20','Срабатывание сигнализации'),
(4,'Пожар','high','ул. Пирогова, д. 15','2025-09-04 13:00','2025-09-04 13:05','2025-09-04 14:00','Офисный пожар'),
(5,'Медицинский','medium','ул. Фрунзе, д. 60','2025-09-05 14:00','2025-09-05 14:05','2025-09-05 14:50','Травма на производстве'),
(1,'Пожар','critical','ул. Красный проспект, д. 12','2025-09-06 15:00','2025-09-06 15:05','2025-09-06 16:00','Пожар на складе'),
(2,'Медицинский','medium','ул. Дуси Ковальчук, д. 55','2025-09-07 16:00','2025-09-07 16:05','2025-09-07 16:40','Обморок'),
(3,'Пожар','high','ул. Сибирская, д. 85','2025-09-08 17:00','2025-09-08 17:05','2025-09-08 18:00','Пожар в гараже'),
(4,'Медицинский','medium','ул. Пирогова, д. 20','2025-09-09 18:00','2025-09-09 18:05','2025-09-09 18:40','Аллергическая реакция'),
(5,'Пожар','critical','ул. Фрунзе, д. 65','2025-09-10 19:00','2025-09-10 19:05','2025-09-10 20:00','Пожар на фабрике'),
(1,'Пожар','high','ул. Ленина, 1','2025-09-01 10:00+00','2025-09-01 10:05+00',  NULL,'Пожар в школе');

-- ==================== EQUIPMENT ====================
INSERT INTO app.equipment(station_id, name, sku, quantity, condition, last_inspected)
VALUES
(1,'Пожарный рукав','EQ-001',10,'good','2025-05-01'),
(2,'Дыхательный аппарат','EQ-002',5,'good','2025-05-02'),
(3,'Гидравлический резак','EQ-003',2, 'serviceable','2025-05-03'),
(4,'Огнетушитель ОП-5','EQ-004',15,'good','2025-05-04'),
(5,'Комплект касок','EQ-005',20,'good','2025-05-05'),
(6,'Тепловизор','EQ-006',1,'good','2025-05-06'),
(7,'Лебёдка','EQ-007',1,'serviceable','2025-05-07'),
(8,'Носилки','EQ-008',2,'good','2025-05-08'),
(9,'Аптечка расширенная','EQ-009',3,'good','2025-05-09'),
(10,'Радиостанции','EQ-010',6,'good','2025-05-10');

-- ==================== RESPONSES ====================
INSERT INTO app.responses(incident_id, vehicle_id, firefighter_id, role_id, assigned_at, arrived_at, cleared_at)
VALUES
(1, 1, 1, 1, '2025-09-01 10:05', '2025-09-01 10:15', '2025-09-01 11:00'),
(2, 3, 3, 4, '2025-09-02 11:05', '2025-09-02 11:15', '2025-09-02 11:45'),
(3, 5, 5, 2, '2025-09-03 12:10', '2025-09-03 12:20', '2025-09-03 12:30'),
(4, 7, 7, 3, '2025-09-04 13:05', '2025-09-04 13:15', '2025-09-04 14:00'),
(5, 9, 9, 5, '2025-09-05 14:05', '2025-09-05 14:20', '2025-09-05 14:50'),
(6, 2, 2, 2, '2025-09-06 15:05', '2025-09-06 15:15', '2025-09-06 16:00'),
(7, 4, 4, 1, '2025-09-07 16:05', '2025-09-07 16:15', '2025-09-07 16:40'),
(8, 6, 6, 3, '2025-09-08 17:05', '2025-09-08 17:20', '2025-09-08 18:00'),
(9, 8, 8, 6, '2025-09-09 18:05', '2025-09-09 18:18', '2025-09-09 18:40'),
(10,10,10,2,'2025-09-10 19:05', '2025-09-10 19:20', '2025-09-10 20:00'),

(11,1,2,(SELECT role_id FROM ref.roles WHERE name='Экипаж'),'2025-09-01 10:06+00','2025-09-01 10:15+00',NULL);

-- ==================== SHIFTS ====================
INSERT INTO app.shifts(firefighter_id, station_id, shift_date, notes)
VALUES
(1, 1, '2025-09-01', 'Ночная смена'),
(2, 1, '2025-09-01', 'Дневная смена'),
(3, 2, '2025-09-02', 'Ночная смена'),
(5, 3, '2025-09-03', 'Дневная смена'),
(7, 4, '2025-09-04', 'Ночная смена'),
(4, 4, '2025-09-05', 'Дневная смена'),
(6, 3, '2025-09-06', 'Ночная смена'),
(8, 4, '2025-09-07', 'Дневная смена'),
(9, 5, '2025-09-08', 'Ночная смена'),
(10, 5, '2025-09-09', 'Дневная смена');


-- Работа с RLS
-- Включаем защиту на уровне строк
ALTER TABLE app.firefighters ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.firefighters FORCE ROW LEVEL SECURITY;
ALTER TABLE app.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.incidents FORCE ROW LEVEL SECURITY;

-- Создание политик
-- Владелец может видеть и добавлять любые строки
CREATE POLICY admin_all ON app.firefighters TO app_owner USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON app.incidents TO app_owner USING (true) WITH CHECK (true);

CREATE POLICY firefighters_select
    ON app.firefighters
    FOR SELECT
    TO app_reader, app_writer
    USING (true);

CREATE POLICY incidents_select
    ON app.incidents
    FOR SELECT
    TO app_reader, app_writer
    USING (true);

REVOKE SELECT ON app.firefighters FROM app_reader;
REVOKE SELECT ON app.firefighters FROM app_writer;

REVOKE SELECT ON app.incidents FROM app_reader;
REVOKE SELECT ON app.incidents FROM app_writer;

GRANT SELECT
    (firefighter_id, station_id, rank_id, hire_date)
ON app.firefighters TO app_reader;

GRANT SELECT 
    (firefighter_id, station_id, rank_id, hire_date)
ON app.firefighters TO app_writer;

GRANT SELECT
    (incident_id, station_id, incident_type, priority, reported_at, dispatched_at, cleared_at)
ON app.incidents TO app_reader;

GRANT SELECT 
    (incident_id, station_id, incident_type, priority, reported_at, dispatched_at, cleared_at)
ON app.incidents TO app_writer;


-- Разрешаем writer вставлять любые строки
CREATE POLICY incidents_insert
  ON app.incidents
  FOR INSERT
  TO app_writer, dml_admin
  WITH CHECK (true);

-- USING — какие строки можно читать/обновлять; WITH CHECK — какими они могут стать
CREATE POLICY incidents_update
  ON app.incidents
  FOR UPDATE
  TO app_writer, dml_admin
  USING (true)
  WITH CHECK (true);

CREATE POLICY incidents_delete
ON app.incidents
FOR DELETE
TO dml_admin
USING (true);

GRANT INSERT, UPDATE, DELETE ON app.incidents TO app_writer;

-- ЛАБА 2
SET ROLE app_owner;

CREATE OR REPLACE FUNCTION app.fn_assign_shift_impl(
  p_firefighter_id integer,
  p_shift_date date,
  p_station_id integer DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS integer
SECURITY DEFINER
SET search_path = pg_catalog, public, app, audit
LANGUAGE plpgsql
AS $$
DECLARE
    v_shift_id integer;
    v_station_id integer;
    eff_role text := COALESCE(NULLIF(current_setting('role', true), ''), session_user);
    v_call_time timestamptz := now();
BEGIN
    BEGIN
        IF eff_role NOT IN ('app_writer', 'dml_admin') THEN
            RAISE EXCEPTION 'Access denied: writer/dml_admin role required'
              USING HINT = 'Обратитесь к security_admin для выдачи роли.';
        END IF;

        IF p_firefighter_id IS NULL OR p_shift_date IS NULL THEN
            RAISE EXCEPTION 'firefighter_id and shift_date are required'
              USING ERRCODE = '22004', DETAIL = 'Переданы NULL параметры.';
        END IF;

        PERFORM 1 FROM app.firefighters WHERE firefighter_id = p_firefighter_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Firefighter % not found', p_firefighter_id;
        END IF;

        IF p_station_id IS NOT NULL THEN
            PERFORM 1 FROM app.stations WHERE station_id = p_station_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Station % not found', p_station_id;
            END IF;
            v_station_id := p_station_id;
        ELSE
            SELECT station_id INTO v_station_id
            FROM app.firefighters
            WHERE firefighter_id = p_firefighter_id;

            IF v_station_id IS NULL THEN
                RAISE EXCEPTION 'Не удалось определить станцию сотрудника %', p_firefighter_id;
            END IF;
        END IF;

        INSERT INTO app.shifts(firefighter_id, shift_date, station_id, notes)
        VALUES (p_firefighter_id, p_shift_date, v_station_id, NULLIF(btrim(p_notes), ''))
        ON CONFLICT (firefighter_id, shift_date) DO UPDATE
           SET station_id = EXCLUDED.station_id,
               notes = COALESCE(NULLIF(btrim(EXCLUDED.notes), ''), app.shifts.notes)
        RETURNING shift_id INTO v_shift_id;

        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'fn_assign_shift_impl', eff_role,
                jsonb_build_object(
                    'p_firefighter_id', p_firefighter_id,
                    'p_shift_date', p_shift_date,
                    'p_station_id', p_station_id,
                    'p_notes', p_notes
                ), true);

        RETURN v_shift_id;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'fn_assign_shift_impl', eff_role,
                jsonb_build_object(
                    'p_firefighter_id', p_firefighter_id,
                    'p_shift_date', p_shift_date,
                    'p_station_id', p_station_id,
                    'p_notes', p_notes
                ), false);
        RAISE;
    END;
END;
$$;

REVOKE ALL ON FUNCTION app.fn_assign_shift_impl(integer,date, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.fn_assign_shift_impl(integer,date,integer, text) TO app_writer, dml_admin;

-- SELECT app.fn_assign_shift_impl(5, '2025-09-03', 2, 'Дневная смена');
-- SELECT app.fn_assign_shift_impl(5, '2025-09-04', NULL, 'Ночная смена');


-- Безопасное закрытие инцидента
CREATE OR REPLACE FUNCTION app.close_incident(
    p_incident_id integer,
    p_cleared_at timestamptz,
    p_comment text DEFAULT NULL
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, app, ref, audit
AS $$
DECLARE
    eff_role text := COALESCE(NULLIF(current_setting('role', true), ''), session_user);
    v_call_time timestamptz := now();
    v_rep timestamptz;
    v_disp timestamptz;
    v_curr_clear timestamptz;
    v_max_assigned timestamptz;
    v_max_arrived timestamptz;
    v_updated integer := 0;
BEGIN
    -- доступ только для писателей данных
    IF eff_role NOT IN ('app_writer', 'dml_admin') THEN
        RAISE EXCEPTION 'Access denied: writer/dml_admin role required'
          USING HINT = 'Обратитесь к security_admin для выдачи роли.';
    END IF;

        IF p_incident_id IS NULL OR p_cleared_at IS NULL THEN
            RAISE EXCEPTION 'incident_id and cleared_at are required'
              USING ERRCODE='22004', DETAIL='Переданы NULL параметры.';
        END IF;

    -- берём инцидент на эксклюзивную блокировку
    SELECT reported_at, dispatched_at, cleared_at
      INTO v_rep, v_disp, v_curr_clear
    FROM app.incidents
    WHERE incident_id = p_incident_id
    FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Инцидент % не найден', p_incident_id
              USING ERRCODE='02000';
        END IF;

        IF v_curr_clear IS NOT NULL THEN
            RAISE EXCEPTION 'Инцидент % уже закрыт (%). Повторное закрытие невозможно.',
                            p_incident_id, v_curr_clear
              USING ERRCODE='22023';
        END IF;

    -- базовая хронология относительно самого инцидента
    IF v_rep  IS NOT NULL AND p_cleared_at < v_rep  THEN
        RAISE EXCEPTION 'cleared_at (%) раньше reported_at (%)', p_cleared_at, v_rep
          USING ERRCODE='22007';
    END IF;
    IF v_disp IS NOT NULL AND p_cleared_at < v_disp THEN
        RAISE EXCEPTION 'cleared_at (%) раньше dispatched_at (%)', p_cleared_at, v_disp
          USING ERRCODE='22007';
    END IF;

        SELECT max(assigned_at), max(arrived_at)
          INTO v_max_assigned, v_max_arrived
        FROM app.responses
        WHERE incident_id = p_incident_id;

        IF v_max_assigned IS NOT NULL AND p_cleared_at < v_max_assigned THEN
            RAISE EXCEPTION 'cleared_at (%) раньше максимального assigned_at (%) среди участников',
                            p_cleared_at, v_max_assigned
              USING ERRCODE='22007';
        END IF;

        IF v_max_arrived IS NOT NULL AND p_cleared_at < v_max_arrived THEN
            RAISE EXCEPTION 'cleared_at (%) раньше максимального arrived_at (%) среди участников',
                            p_cleared_at, v_max_arrived
              USING ERRCODE='22007';
        END IF;

        UPDATE app.responses r
           SET cleared_at = p_cleared_at
         WHERE r.incident_id = p_incident_id
           AND r.cleared_at IS NULL
           AND (r.assigned_at IS NULL OR r.assigned_at <= p_cleared_at)
           AND (r.arrived_at  IS NULL OR r.arrived_at  <= p_cleared_at);
        GET DIAGNOSTICS v_updated = ROW_COUNT;

        IF EXISTS (
            SELECT 1
              FROM app.responses r
             WHERE r.incident_id = p_incident_id
               AND (
                    (r.assigned_at IS NOT NULL AND r.assigned_at > p_cleared_at) OR
                    (r.arrived_at  IS NOT NULL AND r.arrived_at  > p_cleared_at) OR
                    (r.cleared_at  IS NOT NULL AND r.arrived_at IS NOT NULL AND r.cleared_at < r.arrived_at)
                   )
        ) THEN
            RAISE EXCEPTION 'Нарушена хронология в участниках инцидента %, проверьте времена assigned/arrived/cleared', p_incident_id
              USING ERRCODE='22007';
        END IF;

        UPDATE app.incidents
           SET cleared_at  = p_cleared_at,
               description = CASE
                               WHEN NULLIF(btrim(p_comment), '') IS NULL THEN description
                               ELSE COALESCE(description,'') || E'\n[close] ' || btrim(p_comment)
                             END
         WHERE incident_id = p_incident_id;

        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'close_incident', eff_role,
                jsonb_build_object(
                    'p_incident_id', p_incident_id,
                    'p_cleared_at', p_cleared_at,
                    'p_comment', p_comment
                ), true);

        RETURN v_updated;

    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit.function_calls(call_time, function_name, caller_role, input_params, success)
        VALUES (v_call_time, 'close_incident', eff_role,
                jsonb_build_object(
                    'p_incident_id', p_incident_id,
                    'p_cleared_at', p_cleared_at,
                    'p_comment', p_comment
                ), false);
        RAISE;
    END;
END;
$$;

REVOKE ALL ON FUNCTION app.close_incident(integer,timestamptz,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.close_incident(integer,timestamptz,text) TO dml_admin, app_writer;


-- SELECT app.close_incident(1, '2025-09-01 11:00+00', 'Очаг ликвидирован, проливка и вентиляция выполнены');


-- Таблица аудита нарушений правила (лог пишем только в триггерной версии)
CREATE TABLE IF NOT EXISTS audit.shift_violations (
  violation_id bigserial PRIMARY KEY,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  firefighter_id bigint,
  start_at timestamptz,
  end_at timestamptz,
  reason text
);

-- Вариант A: CHECK
CREATE TABLE app.shifts_check (
  shift_id bigserial PRIMARY KEY,
  firefighter_id bigint NOT NULL,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  note text,
  CONSTRAINT shifts_check_time_ok CHECK (
    end_at >= start_at
    AND end_at <= start_at + interval '24 hours'
  )
);

-- Вариант B: TRIGGER
CREATE TABLE app.shifts_trg (
  shift_id  bigserial PRIMARY KEY,
  firefighter_id bigint NOT NULL,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  note text
);

-- Функция-валидатор (и аудит) для триггерной таблицы
CREATE OR REPLACE FUNCTION app.fn_validate_shift()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.end_at < NEW.start_at THEN
    INSERT INTO audit.shift_violations(firefighter_id, start_at, end_at, reason)
    VALUES (NEW.firefighter_id, NEW.start_at, NEW.end_at, 'end_at < start_at');
    RAISE EXCEPTION 'Shift end_at (% ) earlier than start_at (%)', NEW.end_at, NEW.start_at
      USING ERRCODE = '23514';
  ELSIF NEW.end_at > NEW.start_at + interval '24 hours' THEN
    INSERT INTO audit.shift_violations(firefighter_id, start_at, end_at, reason)
    VALUES (NEW.firefighter_id, NEW.start_at, NEW.end_at, 'duration > 24h');
    RAISE EXCEPTION 'Shift duration exceeds 24h (start %, end %)', NEW.start_at, NEW.end_at
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_shift_biu
  BEFORE INSERT OR UPDATE ON app.shifts_trg
  FOR EACH ROW
  EXECUTE FUNCTION app.fn_validate_shift();

SET ROLE fireadmin;
GRANT USAGE ON SCHEMA audit TO app_owner;

CREATE TABLE IF NOT EXISTS audit.function_calls (
    call_time  timestamptz DEFAULT now(),
    function_name text NOT NULL,
    caller_role  text NOT NULL,
    input_params jsonb,
    success      boolean
);
GRANT USAGE ON SCHEMA audit TO u_auditor;
GRANT SELECT ON TABLE audit.function_calls TO u_auditor;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO u_auditor;

GRANT SELECT ON TABLE audit.function_calls TO auditor;

ALTER FUNCTION audit.log_connection()
    SET search_path = 'audit';