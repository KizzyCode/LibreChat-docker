# BEGIN BUILDENV
FROM debian:bookworm-slim AS buildenv

# Install required packages
ENV APT_PACKAGES ca-certificates curl git gnupg
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES}

# Drop root privileges
WORKDIR /tmp
USER nobody

# Fetch mongodb package signing key
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
   | gpg -o mongodb-server-7.0.gpg --dearmor

# Fetch librechat repo, checkout latest tag and slim-down repo
RUN git clone https://github.com/danny-avila/LibreChat ./LibreChat
RUN cd ./LibreChat \
    && git checkout $(git describe --tags --abbrev=0) \
    && rm -rf .git


# BEGIN IMAGE
FROM --platform=amd64 debian:bookworm-slim

# Add mongodb repo
COPY --from=buildenv /tmp/mongodb-server-7.0.gpg /usr/share/keyrings/mongodb-server-7.0.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install required packages
ENV APT_PACKAGES ca-certificates mongodb-org nodejs npm supervisor
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ${APT_PACKAGES} \
    && apt-get autoremove --yes \
    && apt-get clean

# Copy supervisord config
COPY ./files/supervisord.conf /etc/supervisord.conf

# Switch to librechat user context
RUN adduser --disabled-password --uid 10000 librechat
USER librechat
WORKDIR /home/librechat

# Copy app and install node dependencies
COPY --from=buildenv --chown=librechat /tmp/LibreChat ./app
WORKDIR /home/librechat/app
RUN npm clean-install
RUN npm run build:data-provider
RUN npm run frontend

# Setup fixed environment and start services
ENV MONGO_URI "mongodb://127.0.0.1:27017/LibreChat"
ENV HOST 0.0.0.0
ENV PORT 3080
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
