#!/bin/ash
  if [ -z "${1}" ]; then

    if [ ! -z "${SAML_IDP_XML}" ]; then
      eleven log info "saving SAML_IDP_XML to file"
      echo "${SAML_IDP_XML}" > ${APP_ROOT}/etc/idp.xml
    fi

    if [ ! -z "${SAML_SP_XML}" ]; then
      eleven log info "saving SAML_SP_XML to file"
      echo "${SAML_SP_XML}" > ${APP_ROOT}/etc/sp.xml
    fi 

    cd /opt/joplin/server
    set -- "node" \
      ./dist/app.js
    eleven log start
  fi

  exec "$@"