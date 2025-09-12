${{ content_synopsis }} This image will give you a rootless and lightweight Joplin (**SERVER** not client!) installation directly compiled from source and with a few custom optimizations.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image is built and compiled from source
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

**Why is this image not distroless?** Because the developers of this app need to dynamically load modules into node and that only works with dynamic loading enabled, which is only possible in a dynamic linked binary.

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of your SAML configuration files
* **${{ json_root }}/var** - Directory of your files (default storage provider)

${{ content_compose }}

The compose example uses SAML for authentication and disables normal authentication. To use SAML, you need to set a few important properties in your IdP:
${{ github:> [!CAUTION] }}
${{ github:> }}* The SAML response needs to contain the field **email**
${{ github:> }}* The SAML response needs to contain the field **displayName**
${{ github:> }}* The SAML response needs to be signed
${{ github:> }}* The redirect URL needs to point at FQDN/api/saml

For Keycloak simply create the required **User Property** mappers, for all other IdPs check their manual.

${{ content_defaults }}

${{ content_environment }}
| `APP_BASE_URL` | FQDN of the app |  |
| `MAX_TIME_DRIFT` | enable or disable NTP check for time drift | 0 |
| `DB_CLIENT` | which database backend to use | pg |
| `POSTGRES_HOST` | name of postgres host | postgres |
| `POSTGRES_DATABASE` | name of postgres database | postgres |
| `POSTGRES_USER` | name of postgres user | postgres |
| `POSTGRES_PASSWORD` | password for postgres user | |
| `STORAGE_DRIVER` | which storage driver to use | Type=Filesystem;Path=${{ json_root }}/var |
| `SAML_ENABLED` | enable SAML | |
| `DISABLE_BUILTIN_LOGIN_FLOW` | disable normal login if SAML is enabled | |
| `SAML_IDP_CONFIG_FILE` | SAML IDP XML file (can be set inline via SAML_IDP_XML ) | ${{ json_root }}/etc/idp.xml |
| `SAML_SP_CONFIG_FILE` | SAML SP XML file (can be set inline via SAML_SP_XML ) | ${{ json_root }}/etc/sp.xml |
| `SAML_IDP_XML` | inline XML for SAML IDP |  |
| `SAML_SP_XML` | inline XML for SAML SP | |

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}