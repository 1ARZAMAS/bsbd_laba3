
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

CREATE TABLE IF NOT EXISTS ref.segment (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    role_name TEXT NOT NULL,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE app.stations(
    station_id SERIAL PRIMARY KEY,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(11)
);

CREATE TABLE app.firefighters(
    firefighter_id SERIAL PRIMARY KEY,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    station_id INTEGER NOT NULL REFERENCES app.stations(station_id) ON DELETE RESTRICT,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    rank_id INTEGER REFERENCES ref.firefighter_ranks(rank_id) ON DELETE SET NULL,
    phone VARCHAR(11) UNIQUE,
    email VARCHAR(50) UNIQUE,
    hire_date DATE
);

CREATE TABLE app.vehicles(
    vehicle_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    type_id INTEGER REFERENCES ref.vehicle_types(type_id) ON DELETE SET NULL,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    model VARCHAR(100),
    plate_number VARCHAR(50) UNIQUE,
    status_id INTEGER REFERENCES ref.vehicle_statuses(status_id) ON DELETE SET NULL,
    last_inspected DATE
);

CREATE TABLE app.equipment(
    equipment_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    name VARCHAR(50),
    sku VARCHAR(50),
    quantity INTEGER DEFAULT 1 CHECK (quantity >= 0),
    condition VARCHAR(50) DEFAULT 'good' CHECK (condition IN ('good', 'serviceable', 'needs_repair', 'broken')),
    last_inspected DATE
);

CREATE TABLE app.incidents(
    incident_id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES app.stations(station_id) ON DELETE SET NULL,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    incident_type VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('critical', 'high', 'normal', 'medium', 'low')),
    location TEXT,
    reported_at TIMESTAMP WITH TIME ZONE,
    dispatched_at TIMESTAMP WITH TIME ZONE,
    cleared_at TIMESTAMP WITH TIME ZONE,
    description TEXT
);

CREATE TABLE app.responses(
    response_id SERIAL PRIMARY KEY,
    incident_id INTEGER NOT NULL REFERENCES app.incidents(incident_id) ON DELETE CASCADE,
    vehicle_id INTEGER REFERENCES app.vehicles(vehicle_id) ON DELETE SET NULL,
    firefighter_id INTEGER NOT NULL REFERENCES app.firefighters(firefighter_id) ON DELETE SET NULL,
    role_id INTEGER REFERENCES ref.roles(role_id) ON DELETE SET NULL,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    arrived_at TIMESTAMP WITH TIME ZONE,
    cleared_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE app.shifts(
    shift_id SERIAL PRIMARY KEY,
    firefighter_id INTEGER REFERENCES app.firefighters(firefighter_id) ON DELETE CASCADE,
    station_id INTEGER NOT NULL REFERENCES app.stations(station_id) ON DELETE RESTRICT,
    segment_id  int NOT NULL REFERENCES ref.segment(id),
    shift_date DATE,
    notes TEXT,
    CONSTRAINT uq_shift_unique UNIQUE(firefighter_id, shift_date)
);