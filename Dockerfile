FROM python:3.6-slim-buster

RUN /usr/bin/apt-get update && \
    /usr/bin/apt-get install -y --no-install-recommends nginx gcc curl xz-utils git \
        libpcre3-dev libpq-dev libffi-dev libxml2-dev libxslt-dev libssl-dev zlib1g-dev \
        postgresql postgresql-contrib nginx-full && \
    /bin/rm -rf /var/lib/apt/lists/*

ENV APP_DIR /app

ENV DEP_NODE_VERSION 14.16.1
RUN curl -SLO "https://nodejs.org/dist/v${DEP_NODE_VERSION}/node-v${DEP_NODE_VERSION}-linux-x64.tar.xz" && \
    test $(sha256sum node-v${DEP_NODE_VERSION}-linux-x64.tar.xz | cut -d " " -f 1) = 85a89d2f68855282c87851c882d4c4bbea4cd7f888f603722f0240a6e53d89df && \
    /bin/tar -xJf "node-v${DEP_NODE_VERSION}-linux-x64.tar.xz" -C /usr/local --strip-components=1 && \
    /bin/rm "node-v${DEP_NODE_VERSION}-linux-x64.tar.xz" && \
    /bin/mkdir -p ${APP_DIR}

COPY . ${APP_DIR}

WORKDIR ${APP_DIR}

RUN pip install --upgrade digitalmarketplace-developer-tools -r tasks-requirements.txt

RUN invoke install

ENV USER postgres

RUN sed -i 's/peer/trust/g' /etc/postgresql/11/main/pg_hba.conf && sed -i 's/md5/trust/g' /etc/postgresql/11/main/pg_hba.conf

RUN pg_ctlcluster 11 main restart && \
    psql --user ${USER} --command "CREATE DATABASE digitalmarketplace;" && \
    psql --user ${USER} --command "CREATE DATABASE digitalmarketplace_test;"
