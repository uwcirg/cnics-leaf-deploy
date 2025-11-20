-- MariaDB initialization script; run on first start only
CREATE DATABASE IF NOT EXISTS cnics;
GRANT SELECT, CREATE TEMPORARY TABLES ON cnics.* TO `db-user`@`%`;
