DROP DATABASE IF EXISTS rest_api;

CREATE DATABASE rest_api;

USE rest_api;

CREATE TABLE users (
 email VARCHAR(255) NOT NULL,
 firstname VARCHAR(100) NOT NULL,
 lastname VARCHAR(100) NOT NULL,
 password_hash VARCHAR(2056) NOT NULL,
 role VARCHAR(255) NOT NULL
);

INSERT INTO users VALUES
('valentin.varbanov@gmail.com', 'Valentin', 'Varbanov', '10de44fd6625c64fa880ca3409b6a963dbe965e54e3b8cc20278cd6a68c5ed6c', 'Admin');
-- 10de44fd6625c64fa880ca3409b6a963dbe965e54e3b8cc20278cd6a68c5ed6c is the sha256 of 'Ins3curePa$$w0rd'
