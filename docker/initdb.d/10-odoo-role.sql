-- Runs once per cluster, as POSTGRES_USER (the bootstrap superuser), right
-- after the entrypoint created POSTGRES_DB.

-- User used by odoo-bin
CREATE ROLE odoo WITH LOGIN CREATEDB PASSWORD 'dbpassword';
ALTER DATABASE odoo OWNER TO odoo;
