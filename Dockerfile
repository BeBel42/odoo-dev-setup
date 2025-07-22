FROM phusion/baseimage:noble-1.0.2

ENV ODOO_DIR=/app

WORKDIR $ODOO_DIR/odoo

RUN apt-get update -y
RUN apt-get install -y \
	python3 \
	postgresql-client \
	npm \
	git \
	libpq-dev \
	python3-dev \
	python3-pip \
	libldap2-dev \
	python3-dev \
	libsasl2-dev \
	gcc

RUN npm install -g rtlcss

# The setup/debinstall.sh script will parse the debian/control file and install the found packages.
COPY ./odoo/setup/debinstall.sh ./setup/debinstall.sh
COPY ./odoo/debian/control ./debian/control
RUN ./setup/debinstall.sh
# Cleaning files (will be refilled by volume later
RUN rm -rf ./setup ./debian

WORKDIR /app

# Is mapped in docker-compose.yml
ENTRYPOINT ["bash", "entrypoint.bash"]
