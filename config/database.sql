-- Database schema for Online-Terminbuchung System

-- Create database
CREATE DATABASE IF NOT EXISTS terminbuchung;
\c terminbuchung;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Kunden (Providers) table
CREATE TABLE IF NOT EXISTS kunden (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subdomain VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefon VARCHAR(50),
    adresse TEXT,
    branche VARCHAR(100),
    logo_url TEXT,
    primary_color VARCHAR(7) DEFAULT '#3B82F6',
    secondary_color VARCHAR(7) DEFAULT '#1F2937',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin users table
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Working hours table
CREATE TABLE IF NOT EXISTS working_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_working_day BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Break times table
CREATE TABLE IF NOT EXISTS break_times (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Buffer times table
CREATE TABLE IF NOT EXISTS buffer_times (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    before_appointment INTEGER DEFAULT 0, -- minutes
    after_appointment INTEGER DEFAULT 0, -- minutes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    customer_telefon VARCHAR(50),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration INTEGER DEFAULT 30, -- minutes
    bemerkung TEXT,
    status VARCHAR(50) DEFAULT 'confirmed', -- confirmed, cancelled, completed
    cancellation_token UUID DEFAULT uuid_generate_v4(),
    reminder_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Settings table
CREATE TABLE IF NOT EXISTS settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    kunde_id UUID REFERENCES kunden(id) ON DELETE CASCADE,
    sms_reminders BOOLEAN DEFAULT true,
    email_reminders BOOLEAN DEFAULT true,
    reminder_hours INTEGER DEFAULT 24,
    cancellation_deadline_hours INTEGER DEFAULT 12,
    max_advance_booking_days INTEGER DEFAULT 90,
    min_advance_booking_hours INTEGER DEFAULT 2,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_appointments_kunde_date ON appointments(kunde_id, appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON appointments(appointment_date, appointment_time);
CREATE INDEX IF NOT EXISTS idx_appointments_cancellation_token ON appointments(cancellation_token);
CREATE INDEX IF NOT EXISTS idx_working_hours_kunde_day ON working_hours(kunde_id, day_of_week);
CREATE INDEX IF NOT EXISTS idx_break_times_kunde_day ON break_times(kunde_id, day_of_week);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_kunden_updated_at BEFORE UPDATE ON kunden
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing
INSERT INTO kunden (subdomain, name, email, branche) VALUES 
('arztpraxis', 'Dr. Schmidt - Allgemeinmedizin', 'info@arztpraxis.de', 'Medizin'),
('anwalt', 'Rechtsanwalt Müller', 'kontakt@anwalt.de', 'Recht')
ON CONFLICT (subdomain) DO NOTHING;

-- Insert sample working hours for Monday-Friday, 9:00-17:00
INSERT INTO working_hours (kunde_id, day_of_week, start_time, end_time)
SELECT k.id, day, '09:00'::time, '17:00'::time
FROM kunden k
CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS days(day)
WHERE k.subdomain = 'arztpraxis'
ON CONFLICT DO NOTHING;

-- Insert sample settings
INSERT INTO settings (kunde_id, sms_reminders, email_reminders, reminder_hours, cancellation_deadline_hours)
SELECT k.id, true, true, 24, 12
FROM kunden k
WHERE k.subdomain = 'arztpraxis'
ON CONFLICT DO NOTHING;