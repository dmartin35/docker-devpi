# ## Build Python Wheels ##

FROM alpine:3.8 as base
RUN apk add --update --no-cache bash python3 \
    && python3 -m ensurepip \
    && pip3 install --upgrade pip \
    && pip3 install wheel \
    && rm -r /root/.cache

COPY devpi-requirements.txt /requirements.txt
RUN apk add --no-cache --virtual .build-deps gcc python3-dev libffi-dev musl-dev \
    && pip3 wheel --wheel-dir=/srv/wheels -r /requirements.txt

# ## Build Docker image ## 

FROM alpine:3.8

# RUN apk add --update --no-cache bash ca-certificates && update-ca-certificates
RUN apk add --update --no-cache bash ca-certificates python3 \
    && python3 -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && pip3 install --upgrade pip setuptools \
    && update-ca-certificates \
    && rm -r /root/.cache

COPY --from=base /requirements.txt /requirements.txt
COPY --from=base  /srv/wheels /srv/wheels
RUN pip3 install --no-cache-dir --no-index --find-links=/srv/wheels -r /requirements.txt \
    && rm -rf /root/.cache

# Set default server root
ENV DEVPI_HOME=/data \
    DEVPI_HOST=0.0.0.0 \
    DEVPI_PORT=3141 \
    DEVPI_SERVERDIR=/data/server \
    DEVPI_CLIENTDIR=/data/client \
    DEVPI_THEME=semantic-ui

WORKDIR $DEVPI_HOME
VOLUME $DEVPI_HOME

RUN mkdir -p $DEVPI_SERVERDIR && mkdir -p $DEVPI_CLIENTDIR
RUN ls -la /data
EXPOSE $DEVPI_PORT

COPY devpi-client /usr/local/bin/
COPY entrypoint.sh /
CMD ["/entrypoint.sh"]
