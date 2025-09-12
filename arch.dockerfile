# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=laurent22/joplin.git \
      BUILD_ROOT=/joplin

# :: FOREIGN IMAGES
  FROM 11notes/util AS util
  FROM 11notes/util:bin AS util-bin
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:tini AS distroless-tini
  FROM 11notes/distroless:localhealth AS distroless-localhealth
  FROM 11notes/distroless:ds AS distroless-ds


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: JOPLIN
  FROM node:lts-alpine AS build
  COPY --from=util-bin / /
  COPY --from=distroless-ds / /
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT
  RUN set -ex; \
    apk --update --no-cache add \
      git \
      python3;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} v${APP_VERSION};

  RUN set -ex; \
    npm install -g npm; \
    npm install -g corepack; \
    corepack enable;

  RUN set -ex; \
    cd ${BUILD_ROOT}/packages; \
    for PACKAGE in *; do \
      case ${PACKAGE} in \
        turndown|turndown-plugin-gfm|fork-htmlparser2|server|fork.sax|fork-uslug|htmlpack|renderer|tools|utils|lib);; \
        *) rm -rf ${BUILD_ROOT}/packages/${PACKAGE};; \
      esac; \
    done;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    sed -i '/onenote-converter/d' ./packages/lib/package.json;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    # modifications for silent health check (no log, no error)
    sed -i "s/const host1 = (new URL(requestOrigin)).host;/if(requestOrigin.match('127.0.0.1')){return(true)}; const host1 = (new URL(requestOrigin)).host;/" ./packages/server/src/utils/routeUtils.ts; \
    sed -i 's|ctx.joplin.appLogger().info(`${ctx.request.method} ${ctx.path} (${ctx.response.status}) (${requestDuration}ms)`);|if(!ctx.path.match(`/api/ping`)){ctx.joplin.appLogger().info(`${ctx.request.method} ${ctx.path} (${ctx.response.status}) (${requestDuration}ms)`);}|' ./packages/server/src/middleware/routeHandler.ts;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    # set temp to actual /tmp for temporary files and log files
    sed -i 's#${rootDir}/temp#/tmp#' ./packages/server/src/config.ts; \
    sed -i 's#${rootDir}/logs#/tmp#' ./packages/server/src/config.ts;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    BUILD_SEQUENCIAL=1 \
      yarn install --refresh-lockfile --inline-builds;

# :: FILE-SYSTEM
  FROM alpine AS file-system
  COPY ./rootfs /distroless
  ARG APP_ROOT
  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/etc; \
    mkdir -p /distroless${APP_ROOT}/var; \
    chmod +x -R /distroless/usr/local/bin;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM node:lts-alpine

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE \
        BUILD_ROOT

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV NODE_ENV=production \
        RUNNING_IN_DOCKER=1 \
        MAX_TIME_DRIFT=0 \
        DB_CLIENT="pg" \
        POSTGRES_DATABASE="postgres" \
        POSTGRES_USER="postgres" \
        POSTGRES_HOST="postgres" \
        STORAGE_DRIVER="Type=Filesystem;Path=${APP_ROOT}/var" \
        SAML_IDP_CONFIG_FILE="${APP_ROOT}/etc/idp.xml" \
        SAML_SP_CONFIG_FILE="${APP_ROOT}/etc/sp.xml"

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-tini / /
    COPY --from=distroless-localhealth / /
    COPY --from=util / /
    COPY --from=build --chown=${APP_UID}:${APP_GID} ${BUILD_ROOT}/packages /opt/joplin
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var"]

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:22300/api/ping"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]