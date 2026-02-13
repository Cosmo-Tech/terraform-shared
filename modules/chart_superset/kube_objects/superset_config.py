import os
import logging
from logging import getLogger
from flask_appbuilder.security.manager import AUTH_OAUTH
from superset import SupersetSecurityManager

logger = logging.getLogger()
log = getLogger(__name__)
log.setLevel(logging.DEBUG)

### This file is based on this one https://github.com/apache/superset/blob/master/superset/config.py

# Start Utility functions
def is_boolean_yes(var):
    if var == 1 or var == "yes" or var == "true":
        return True
    return False

def env(key, default=None):
    return os.getenv(key, default)
# End Utility functions

# Start custom_sso_security_manager (https://superset.apache.org/docs/configuration/configuring-superset/#custom-oauth2-configuration)
class KeycloakSecurity(SupersetSecurityManager):
    """
    Create a new SecurityManager with own oauth_user_info to handle the information from Keycloak
    """

    def oauth_user_info(self, provider, resp=None):
        log.debug("Keycloak response received : {0}".format(resp))
        id_token = resp["id_token"]
        log.debug("ID Token: %s", id_token)
        userinfo = resp["userinfo"]
        log.debug("Token userinfo: %s", userinfo)
        issuer = userinfo["iss"]
        log.debug("User info issuer: %s", issuer)
        me = self.appbuilder.sm.oauth_remotes[provider].get(
            f'{issuer}/protocol/openid-connect/userinfo'
        )
        me.raise_for_status()
        data = me.json()
        log.debug("User info from Keycloak: %s", data)
        return {
            "name": data["name"],
            "email": data["email"],
            "first_name": data["given_name"],
            "last_name": data["family_name"],
            "id": data["preferred_username"],
            "username": data["preferred_username"],
            "role_keys": data.get("userRoles", [])
        }
# End custom_sso_security_manager

## URLs config
ROOT_URL = 'https://superset-warp.api.cosmotech.com'
LOGOUT_REDIRECT_URL = 'https://superset-warp.api.cosmotech.com'

# Auth config
AUTH_USER_REGISTRATION = True
AUTH_TYPE = AUTH_OAUTH
CUSTOM_SECURITY_MANAGER = KeycloakSecurity
# https://github.com/apache/superset/blob/5.0/docs/docs/configuration/configuring-superset.mdx#mapping-oauth-groups-to-superset-roles)
AUTH_ROLES_MAPPING = {
    "Platform.Admin": ["Admin"],
    "Organization.User": ["Gamma"],
}
AUTH_ROLES_SYNC_AT_LOGIN = True

OAUTH_PROVIDERS = [
    {
        "name": "sphinx",
        "icon": "fa-key",
        "token_key": "access_token",
        "remote_app": {
            "client_id": "cosmotech-superset-client",
            "client_secret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            "client_kwargs": {"scope": "openid profile email"},
            "server_metadata_url": "https://warp.api.cosmotech.com/keycloak/realms/sphinx/.well-known/openid-configuration"
        }
    },
    {
        "name": "eng-api-ci",
        "icon": "fa-key",
        "token_key": "access_token",
        "remote_app": {
            "client_id": "cosmotech-superset-client",
            "client_secret": "xxxxxxxxxxxxxxxxxxxxxxxxx",
            "client_kwargs": {"scope": "openid profile email"},
            "server_metadata_url": "https://warp.api.cosmotech.com/keycloak/realms/eng-api-ci/.well-known/openid-configuration"
        }
    }
]

# Flask App Builder configuration
# Your App secret key will be used for securely signing the session cookie
# and encrypting sensitive information on the database
# Make sure you are changing this key for your deployment with a strong key.
# Alternatively you can set it with `SUPERSET_SECRET_KEY` environment variable.
# You MUST set this for production environments or the server will refuse
# to start and you will see an error in the logs accordingly.
# SECRET_KEY = 'xxxxxxxxxxxxxxxxxxxxxxx'

# Database config
##
DB_DIALECT = env("SUPERSET_DATABASE_DIALECT", "postgresql+psycopg2")
DB_USER = env("SUPERSET_DATABASE_USER")
DB_PASSWORD = env("SUPERSET_DATABASE_PASSWORD")
DB_HOST = env("SUPERSET_DATABASE_HOST", "postgresql")
DB_PORT = env("SUPERSET_DATABASE_PORT_NUMBER", "5432")
DB_NAME = env("SUPERSET_DATABASE_NAME")
DB_PARAMS = "?sslmode=require" if is_boolean_yes(env("SUPERSET_DATABASE_USE_SSL", "no")) else ""
DB_AUTH = f"{DB_USER}:{DB_PASSWORD}@" if DB_PASSWORD else ""
SQLALCHEMY_DATABASE_URI = f"{DB_DIALECT}://{DB_AUTH}{DB_HOST}:{DB_PORT}/{DB_NAME}{DB_PARAMS}"
SQLALCHEMY_TRACK_MODIFICATIONS = True

# Optional functionality
# https://github.com/apache/superset/blob/142b2cc42543876c607c4a258dfac018da1f1d81/superset/config.py#L539
### Role-based access control for dashboards
### Enables Alerts and Reports functionality
### Enable embedded Superset functionality
FEATURE_FLAGS = {'DASHBOARD_RBAC': True,
                 'ALERT_REPORTS': True,
                 'EMBEDDED_SUPERSET': True}


# After this : volatile config to try to get guest access tokens
GUEST_ROLE_NAME = "Gamma"
GUEST_TOKEN_JWT_AUDIENCE = "superset"
GUEST_TOKEN_JWT_SECRET = "superset-warp.api.cosmotech.com/@cosmotech_we_use_superset"
# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = False

# Cross Origin Config
# default value
#ENABLE_CORS = True
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'resources':['*'],
    'origins': ["https://superset-warp.api.cosmotech.com"]
}

# Talisman Config
TALISMAN_ENABLED = True
TALISMAN_CONFIG = {
    "content_security_policy": {
        "frame-ancestors": ["https://superset-warp.api.cosmotech.com"]
    },
    "force_https": False,
    "force_https_permanent": False,
    "frame_options": "ALLOWFROM",
    "frame_options_allow_from": "*"
}