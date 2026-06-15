-- Active: 1718386450000@@127.0.0.1@5432@planner_db
-- Active database connection not required to run, this is standard PostgreSQL DDL.

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    student_id VARCHAR(100) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    password_hash VARCHAR(255),
    branch VARCHAR(100),
    level VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    verification_code VARCHAR(10),
    profile_image TEXT
);

-- Create rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    building VARCHAR(100),
    is_occupied BOOLEAN DEFAULT FALSE,
    capacity INTEGER
);

-- Create exams table
CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY,
    subject VARCHAR(255) NOT NULL,
    exam_date DATE NOT NULL,
    exam_time VARCHAR(50) NOT NULL,
    room VARCHAR(100) REFERENCES rooms(name) ON DELETE SET NULL,
    teacher VARCHAR(255),
    duration VARCHAR(100),
    level VARCHAR(50)
);

-- Create results table
CREATE TABLE IF NOT EXISTS results (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    grade DECIMAL(4,2) NOT NULL,
    credits INTEGER,
    semester VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create focus sessions table
CREATE TABLE IF NOT EXISTS focus_sessions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    duration_minutes INTEGER NOT NULL,
    session_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
