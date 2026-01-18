![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# JOPLIN
![size](https://img.shields.io/badge/image_size-1GB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/joplin?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-joplin?color=7842f5">](https://github.com/11notes/docker-joplin/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run joplin smaller, lightweight and more secure

# INTRODUCTION 📢

[Joplin](https://github.com/laurent22/joplin) (created by [laurent22](https://github.com/laurent22)) is a free, open source note taking and to-do application, which can handle a large number of notes organised into notebooks. The notes are searchable, can be copied, tagged and modified either from the applications directly or from your own text editor. The notes are in Markdown format.

# SYNOPSIS 📖
**What can I do with this?** This image will give you a rootless and lightweight Joplin (**SERVER** not client!) installation directly compiled from source and with a few custom optimizations.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image is built and compiled from source
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/joplin | 1GB | 1000:1000 | ❌ | amd64, arm64 |
| joplin/server | 2GB | 1001:1001 | ❌ | amd64, arm64 |

**Why is this image not distroless?** Because the developers of this app need to dynamically load modules into node and that only works with dynamic loading enabled, which is only possible in a dynamic linked binary.

# VOLUMES 📁
* **/joplin/etc** - Directory of your SAML configuration files
* **/joplin/var** - Directory of your files (default storage provider)

# COMPOSE ✂️
```yaml
name: "joplin"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  postgres:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-postgres
    image: "11notes/postgres:18"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_BACKUP_SCHEDULE: "0 3 * * *"
    networks:
      backend:
    volumes:
      - "postgres.etc:/postgres/etc"
      - "postgres.var:/postgres/var"
      - "postgres.backup:/postgres/backup"
    tmpfs:
      - "/postgres/run:uid=1000,gid=1000"
      - "/postgres/log:uid=1000,gid=1000"
    restart: "always"

  server:
    depends_on:
      postgres:
        condition: "service_healthy"
        restart: true
    image: "11notes/joplin:3.5.12"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      APP_BASE_URL: "https://${FQDN}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      SAML_ENABLED: true
      DISABLE_BUILTIN_LOGIN_FLOW: true
      SAML_IDP_XML: |-
        <md:EntityDescriptor entityID="https://${SSO_FQDN}/realms/${SSO_REALM}">
          <md:IDPSSODescriptor WantAuthnRequestsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
            <md:KeyDescriptor use="signing">
              <ds:KeyInfo>
                <ds:KeyName>${SSO_CRT_NAME}</ds:KeyName>
                <ds:X509Data>
                  <ds:X509Certificate>${SSO_CRT_BASE64}</ds:X509Certificate>
                </ds:X509Data>
              </ds:KeyInfo>
            </md:KeyDescriptor>
            <md:ArtifactResolutionService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml/resolve" index="0"/>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</md:NameIDFormat>
            <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
            <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact" Location="https://${SSO_FQDN}/realms/${SSO_REALM}/protocol/saml"/>
          </md:IDPSSODescriptor>
        </md:EntityDescriptor>
      SAML_SP_XML: |-
        <?xml version="1.0"?>
        <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" validUntil="2026-12-31T23:59:59Z" cacheDuration="PT604800S" entityID="${SSO_CLIENT_ID}">
            <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
                <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
                <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://${FQDN}/api/saml" index="0" />
            </md:SPSSODescriptor>
        </md:EntityDescriptor>
    volumes:
      - "server.etc:/joplin/etc"
      - "server.var:/joplin/var"
    tmpfs:
      # required for read-only
      - "/tmp:uid=1000,gid=1000"
    ports:
      - "3000:22300/tcp"
    networks:
      frontend:
      backend:
    restart: "always"

volumes:
  server.etc:
  server.var:
  postgres.etc:
  postgres.var:
  postgres.backup:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

The compose example uses SAML for authentication and disables normal authentication. To use SAML, you need to set a few important properties in your IdP:
> [!CAUTION]
>* The SAML response needs to contain the field **email**
>* The SAML response needs to contain the field **displayName**
>* The SAML response needs to be signed
>* The redirect URL needs to point at FQDN/api/saml

For Keycloak simply create the required **User Property** mappers, for all other IdPs check their manual.

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /joplin | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |
| `APP_BASE_URL` | FQDN of the app |  |
| `MAX_TIME_DRIFT` | enable or disable NTP check for time drift | 0 |
| `DB_CLIENT` | which database backend to use | pg |
| `POSTGRES_HOST` | name of postgres host | postgres |
| `POSTGRES_DATABASE` | name of postgres database | postgres |
| `POSTGRES_USER` | name of postgres user | postgres |
| `POSTGRES_PASSWORD` | password for postgres user | |
| `STORAGE_DRIVER` | which storage driver to use | Type=Filesystem;Path=/joplin/var |
| `SAML_ENABLED` | enable SAML | |
| `DISABLE_BUILTIN_LOGIN_FLOW` | disable normal login if SAML is enabled | |
| `SAML_IDP_CONFIG_FILE` | SAML IDP XML file (can be set inline via SAML_IDP_XML ) | /joplin/etc/idp.xml |
| `SAML_SP_CONFIG_FILE` | SAML SP XML file (can be set inline via SAML_SP_XML ) | /joplin/etc/sp.xml |
| `SAML_IDP_XML` | inline XML for SAML IDP |  |
| `SAML_SP_XML` | inline XML for SAML SP | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [3.5.12](https://hub.docker.com/r/11notes/joplin/tags?name=3.5.12)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:3.5.12``` you can use ```:3``` or ```:3.5```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/joplin:3.5.12
docker pull ghcr.io/11notes/joplin:3.5.12
docker pull quay.io/11notes/joplin:3.5.12
```

# SOURCE 💾
* [11notes/joplin](https://github.com/11notes/docker-joplin)

# PARENT IMAGE 🏛️
* [node:lts-stable](${{ json_readme_parent_url }})

# BUILT WITH 🧰
* [joplin](https://github.com/laurent22/joplin)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-joplin/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-joplin/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-joplin/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 18.01.2026, 06:36:27 (CET)*