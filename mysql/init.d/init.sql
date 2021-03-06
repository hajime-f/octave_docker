CREATE DATABASE IF NOT EXISTS octave_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'octave_user'@'%' IDENTIFIED BY 'octave';
GRANT ALL PRIVILEGES ON octave_db.* TO 'octave_user'@'%';
ALTER DATABASE octave_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
FLUSH PRIVILEGES;
