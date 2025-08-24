FROM phusion/baseimage:noble-1.0.2

ENV ODOO_USER=root
ENV ODOO_DIR=/app

WORKDIR $ODOO_DIR/community

RUN apt-get update -y && apt-get install -y \
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
	gcc \
	python3-inotify

RUN npm install -g rtlcss

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

RUN if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59  ;; \
    "arm64")  WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=5312d7d34a25b321282929df82e3574319aed25c  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# The setup/debinstall.sh script will parse the debian/control file and install the found packages.
COPY ./community/setup/debinstall.sh ./setup/debinstall.sh
COPY ./community/debian/control ./debian/control
RUN ./setup/debinstall.sh
# Cleaning files (will be refilled by volume later)
RUN rm -rf ./setup ./debian

# Install google chrome for tour testing (it's what's used in the runbot)
RUN curl -sSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o google-chrome.deb && \
    apt-get install -y ./google-chrome.deb && \
    rm -f google-chrome.deb

# Set default user when running the container
USER $ODOO_USER
WORKDIR $ODOO_DIR

# Is mapped in docker-compose.yml
ENTRYPOINT ["bash", "scripts/entrypoint.bash"]

# Odoo
EXPOSE 8069 8071 8072
# Debugpy
EXPOSE 5678

