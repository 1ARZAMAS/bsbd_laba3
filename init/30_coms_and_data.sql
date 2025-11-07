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

INSERT INTO ref.segment(name, role_name) VALUES
('Пожарная часть №1', 'stat_user_1'),
('Пожарная часть №2', 'stat_user_2'),
('Пожарная часть №3', 'stat_user_3'),
('Пожарная часть №4', 'stat_user_4'),
('Пожарная часть №5', 'stat_user_5'),
('Пожарная часть №6', 'stat_user_6'),
('Пожарная часть №7', 'stat_user_7'),
('Пожарная часть №8', 'stat_user_8'),
('Пожарная часть №9', 'stat_user_9'),
('Пожарная часть №10', 'stat_user_10');

-- ==================== STATIONS ====================
INSERT INTO app.stations(segment_id, name, address, phone)
VALUES
((SELECT id FROM ref.segment WHERE name='Пожарная часть №1'), 'Пожарная часть №1', 'ул. Октябрьская, 86, Новосибирск', '83832237970'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №2'), 'Пожарная часть №2', 'ул. Карпатская, 1, Новосибирск', '83832744613'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №3'), 'Пожарная часть №3', 'ул. Кирова, 130, Новосибирск', '83832665117'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №4'), 'Пожарная часть №4', 'ул. Комбинатская, 8, Новосибирск', '83832790101'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №5'), 'Пожарная часть №5', 'ул. Вавилова, 1а, Новосибирск', '83832260452'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №6'), 'Пожарная часть №6', 'ул. Широкая, 38, Новосибирск', '83833415221'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №7'), 'Пожарная часть №7', 'ул. Эйхе, 9, Новосибирск', '83832665117'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №8'), 'Пожарная часть №8', 'ул. Кутателадзе, 3, Новосибирск', '83833320748'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №9'), 'Пожарная часть №9', 'ул. Сибиряков-Гвардейцев, 52, Новосибирск', '83833535031'),
((SELECT id FROM ref.segment WHERE name='Пожарная часть №10'), 'Пожарная часть №10', 'ул. Чекалина, 13а, Новосибирск', '83832747680');

-- ==================== FIREFIGHTERS ====================
INSERT INTO app.firefighters(segment_id, station_id, first_name, last_name, rank_id, phone, email, hire_date)
VALUES
((SELECT segment_id FROM app.stations WHERE station_id=1), 1,'Иван','Иванов',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Капитан'),'89130000001','ivan.ivanov@nsfire.ru','2015-01-10'),
((SELECT segment_id FROM app.stations WHERE station_id=1), 1,'Александра','Смирнова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Лейтенант'),'89130000002','alexandra.smirnova@nsfire.ru','2016-02-15'),
((SELECT segment_id FROM app.stations WHERE station_id=2), 2,'Борис','Петров',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Пожарный'),'89130000003','boris.petrov@nsfire.ru','2017-03-20'),
((SELECT segment_id FROM app.stations WHERE station_id=2), 2,'Карина','Васильева',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Пожарный'),'89130000004','karina.vasilieva@nsfire.ru','2018-04-25'),
((SELECT segment_id FROM app.stations WHERE station_id=3), 3,'Дмитрий','Сидоров',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Лейтенант'),'89130000005','dmitry.sidorov@nsfire.ru','2019-05-30'),
((SELECT segment_id FROM app.stations WHERE station_id=3), 3,'Елена','Кузнецова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Капитан'),'89130000006','elena.kuznetsova@nsfire.ru','2020-06-10'),
((SELECT segment_id FROM app.stations WHERE station_id=4), 4,'Фёдор','Морозов',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Старший пожарный'),'89130000007','fedor.morozov@nsfire.ru','2016-07-15'),
((SELECT segment_id FROM app.stations WHERE station_id=4), 4,'Галина','Волкова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Сержант'),'89130000008','galina.volkova@nsfire.ru','2017-08-20'),
((SELECT segment_id FROM app.stations WHERE station_id=5), 5,'Геннадий','Новиков',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Старший лейтенант'),'89130000009','gennadiy.novikov@nsfire.ru','2018-09-25'),
((SELECT segment_id FROM app.stations WHERE station_id=5), 5,'Ирина','Тарасова',(SELECT rank_id FROM ref.firefighter_ranks WHERE rank='Младший сержант'),'89130000010','irina.tarasova@nsfire.ru','2019-10-30');

-- ==================== VEHICLES ====================
INSERT INTO app.vehicles(station_id, type_id, segment_id, model, plate_number, status_id, last_inspected)
VALUES
(1, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'),
    (SELECT segment_id FROM app.stations WHERE station_id=1), 'AC-1000','НС01-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),      '2025-01-01'),
(1, (SELECT type_id FROM ref.vehicle_types WHERE type='Автолестница'),
    (SELECT segment_id FROM app.stations WHERE station_id=1), 'AL-500','НС01-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),     '2025-01-05'),
(2, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'),
    (SELECT segment_id FROM app.stations WHERE station_id=2), 'RS-300','НС02-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),      '2025-02-01'),
(2, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'),
    (SELECT segment_id FROM app.stations WHERE station_id=2), 'AC-1200','НС02-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='out_of_service'), '2025-02-05'),
(3, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'),
    (SELECT segment_id FROM app.stations WHERE station_id=3), 'AC-1100','НС03-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),      '2025-03-01'),
(3, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'),
    (SELECT segment_id FROM app.stations WHERE station_id=3), 'RS-350','НС03-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),     '2025-03-05'),
(4, (SELECT type_id FROM ref.vehicle_types WHERE type='Автолестница'),
    (SELECT segment_id FROM app.stations WHERE station_id=4), 'AL-600','НС04-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),      '2025-04-01'),
(4, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'),
    (SELECT segment_id FROM app.stations WHERE station_id=4), 'AC-1300','НС04-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='available'),      '2025-04-05'),
(5, (SELECT type_id FROM ref.vehicle_types WHERE type='Спасательный'),
    (SELECT segment_id FROM app.stations WHERE station_id=5), 'RS-400','НС05-01',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='in_service'),     '2025-05-01'),
(5, (SELECT type_id FROM ref.vehicle_types WHERE type='Автоцистерна'),
    (SELECT segment_id FROM app.stations WHERE station_id=5), 'AC-1400','НС05-02',
    (SELECT status_id FROM ref.vehicle_statuses WHERE status='out_of_service'), '2025-05-05');

-- ==================== INCIDENTS ====================
INSERT INTO app.incidents(station_id, segment_id, incident_type, priority, location, reported_at, dispatched_at, cleared_at, description)
VALUES
(1, (SELECT segment_id FROM app.stations WHERE station_id=1), 'Пожар','high','ул. Красный проспект, д. 10','2025-09-01 10:00','2025-09-01 10:05','2025-09-01 11:00','Пожар в квартире'),
(2, (SELECT segment_id FROM app.stations WHERE station_id=2), 'Медицинский','medium','ул. Дуси Ковальчук, д. 50','2025-09-02 11:00','2025-09-02 11:05','2025-09-02 11:45','Сердечный приступ'),
(3, (SELECT segment_id FROM app.stations WHERE station_id=3), 'Ложная тревога','low','ул. Сибирская, д. 80','2025-09-03 12:00','2025-09-03 12:10','2025-09-03 12:20','Срабатывание сигнализации'),
(4, (SELECT segment_id FROM app.stations WHERE station_id=4), 'Пожар','high','ул. Пирогова, д. 15','2025-09-04 13:00','2025-09-04 13:05','2025-09-04 14:00','Офисный пожар'),
(5, (SELECT segment_id FROM app.stations WHERE station_id=5), 'Медицинский','medium','ул. Фрунзе, д. 60','2025-09-05 14:00','2025-09-05 14:05','2025-09-05 14:50','Травма на производстве'),
(1, (SELECT segment_id FROM app.stations WHERE station_id=1), 'Пожар','critical','ул. Красный проспект, д. 12','2025-09-06 15:00','2025-09-06 15:05','2025-09-06 16:00','Пожар на складе'),
(2, (SELECT segment_id FROM app.stations WHERE station_id=2), 'Медицинский','medium','ул. Дуси Ковальчук, д. 55','2025-09-07 16:00','2025-09-07 16:05','2025-09-07 16:40','Обморок'),
(3, (SELECT segment_id FROM app.stations WHERE station_id=3), 'Пожар','high','ул. Сибирская, д. 85','2025-09-08 17:00','2025-09-08 17:05','2025-09-08 18:00','Пожар в гараже'),
(4, (SELECT segment_id FROM app.stations WHERE station_id=4), 'Медицинский','medium','ул. Пирогова, д. 20','2025-09-09 18:00','2025-09-09 18:05','2025-09-09 18:40','Аллергическая реакция'),
(5, (SELECT segment_id FROM app.stations WHERE station_id=5), 'Пожар','critical','ул. Фрунзе, д. 65','2025-09-10 19:00','2025-09-10 19:05','2025-09-10 20:00','Пожар на фабрике'),
(1, (SELECT segment_id FROM app.stations WHERE station_id=1), 'Пожар','high','ул. Ленина, 1','2025-09-01 10:00+00','2025-09-01 10:05+00',  NULL,'Пожар в школе');

-- ==================== EQUIPMENT ====================
INSERT INTO app.equipment(station_id, segment_id, name, sku, quantity, condition, last_inspected)
VALUES
(1,  (SELECT segment_id FROM app.stations WHERE station_id=1), 'Пожарный рукав','EQ-001',10,'good','2025-05-01'),
(2,  (SELECT segment_id FROM app.stations WHERE station_id=2), 'Дыхательный аппарат','EQ-002',5,'good','2025-05-02'),
(3,  (SELECT segment_id FROM app.stations WHERE station_id=3), 'Гидравлический резак','EQ-003',2, 'serviceable','2025-05-03'),
(4,  (SELECT segment_id FROM app.stations WHERE station_id=4), 'Огнетушитель ОП-5','EQ-004',15,'good','2025-05-04'),
(5,  (SELECT segment_id FROM app.stations WHERE station_id=5), 'Комплект касок','EQ-005',20,'good','2025-05-05'),
(6,  (SELECT segment_id FROM app.stations WHERE station_id=6), 'Тепловизор','EQ-006',1,'good','2025-05-06'),
(7,  (SELECT segment_id FROM app.stations WHERE station_id=7), 'Лебедка','EQ-007',1,'serviceable','2025-05-07'),
(8,  (SELECT segment_id FROM app.stations WHERE station_id=8), 'Носилки','EQ-008',2,'good','2025-05-08'),
(9,  (SELECT segment_id FROM app.stations WHERE station_id=9), 'Аптечка расширенная','EQ-009',3,'good','2025-05-09'),
(10, (SELECT segment_id FROM app.stations WHERE station_id=10), 'Радиостанции','EQ-010',6,'good','2025-05-10');


-- ==================== RESPONSES ====================
INSERT INTO app.responses(incident_id, vehicle_id, firefighter_id, role_id, segment_id, assigned_at, arrived_at, cleared_at)
VALUES
(1,  1,  1,  1,  (SELECT segment_id FROM app.incidents WHERE incident_id=1),  '2025-09-01 10:05', '2025-09-01 10:15', '2025-09-01 11:00'),
(2,  3,  3,  4,  (SELECT segment_id FROM app.incidents WHERE incident_id=2),  '2025-09-02 11:05', '2025-09-02 11:15', '2025-09-02 11:45'),
(3,  5,  5,  2,  (SELECT segment_id FROM app.incidents WHERE incident_id=3),  '2025-09-03 12:10', '2025-09-03 12:20', '2025-09-03 12:30'),
(4,  7,  7,  3,  (SELECT segment_id FROM app.incidents WHERE incident_id=4),  '2025-09-04 13:05', '2025-09-04 13:15', '2025-09-04 14:00'),
(5,  9,  9,  5,  (SELECT segment_id FROM app.incidents WHERE incident_id=5),  '2025-09-05 14:05', '2025-09-05 14:20', '2025-09-05 14:50'),
(6,  2,  2,  2,  (SELECT segment_id FROM app.incidents WHERE incident_id=6),  '2025-09-06 15:05', '2025-09-06 15:15', '2025-09-06 16:00'),
(7,  4,  4,  1,  (SELECT segment_id FROM app.incidents WHERE incident_id=7),  '2025-09-07 16:05', '2025-09-07 16:15', '2025-09-07 16:40'),
(8,  6,  6,  3,  (SELECT segment_id FROM app.incidents WHERE incident_id=8),  '2025-09-08 17:05', '2025-09-08 17:20', '2025-09-08 18:00'),
(9,  8,  8,  6,  (SELECT segment_id FROM app.incidents WHERE incident_id=9),  '2025-09-09 18:05', '2025-09-09 18:18', '2025-09-09 18:40'),
(10,10,10, 2,  (SELECT segment_id FROM app.incidents WHERE incident_id=10), '2025-09-10 19:05', '2025-09-10 19:20', '2025-09-10 20:00'),

(11, 1, 2, (SELECT role_id FROM ref.roles WHERE name='Экипаж'),(SELECT segment_id FROM app.incidents WHERE incident_id=11),
     '2025-09-01 10:06+00','2025-09-01 10:15+00',NULL);

-- ==================== SHIFTS ====================
INSERT INTO app.shifts(firefighter_id, station_id, segment_id, shift_date, notes)
VALUES
(1,  1, (SELECT segment_id FROM app.stations WHERE station_id=1),  '2025-09-01', 'Ночная смена'),
(2,  1, (SELECT segment_id FROM app.stations WHERE station_id=1),  '2025-09-01', 'Дневная смена'),
(3,  2, (SELECT segment_id FROM app.stations WHERE station_id=2),  '2025-09-02', 'Ночная смена'),
(5,  3, (SELECT segment_id FROM app.stations WHERE station_id=3),  '2025-09-03', 'Дневная смена'),
(7,  4, (SELECT segment_id FROM app.stations WHERE station_id=4),  '2025-09-04', 'Ночная смена'),
(4,  4, (SELECT segment_id FROM app.stations WHERE station_id=4),  '2025-09-05', 'Дневная смена'),
(6,  3, (SELECT segment_id FROM app.stations WHERE station_id=3),  '2025-09-06', 'Ночная смена'),
(8,  4, (SELECT segment_id FROM app.stations WHERE station_id=4),  '2025-09-07', 'Дневная смена'),
(9,  5, (SELECT segment_id FROM app.stations WHERE station_id=5),  '2025-09-08', 'Ночная смена'),
(10, 5, (SELECT segment_id FROM app.stations WHERE station_id=5),  '2025-09-09', 'Дневная смена');
