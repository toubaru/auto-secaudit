FROM jenkins

USER root
RUN apt-get update \
    && apt-get install -y jq libxml2-utils nkf git \
    && rm -rf /var/lib/apt/lists/*

