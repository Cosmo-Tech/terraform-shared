import os
import logging
import json
from logging import getLogger
from flask_appbuilder.security.manager import AUTH_OAUTH
from superset import SupersetSecurityManager
from flask_caching.backends.rediscache import RedisCache

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
        log.debug("Oauth2 provider: '{0}'.".format(provider))
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
ROOT_URL = 'https://superset-${CLUSTER_DOMAIN}'
LOGOUT_REDIRECT_URL = 'https://superset-${CLUSTER_DOMAIN}'

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

OAUTH_PROVIDERS = json.loads(env("SUPERSET_OAUTH_PROVIDERS", "[]"))

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

## Redis settings
##
REDIS_HOST = env("REDIS_HOST", "redis")
REDIS_PORT = env("REDIS_PORT_NUMBER", "6379")
REDIS_CELERY_DB = env("REDIS_CELERY_DB", "0")
REDIS_DB = env("REDIS_DB", "1")
REDIS_PASSWORD = env("REDIS_PASSWORD")
REDIS_USER = env("REDIS_USER", "")
REDIS_TLS_ENABLED = env("REDIS_TLS_ENABLED", False)
REDIS_SSL_CERT_REQS = env("REDIS_SSL_CERT_REQS")
REDIS_URL_PARAMS = f"ssl_cert_reqs={REDIS_SSL_CERT_REQS}" if REDIS_SSL_CERT_REQS else ""
REDIS_AUTH = f"{REDIS_USER}:{REDIS_PASSWORD}@" if REDIS_PASSWORD else ""
REDIS_BASE_URL = f"redis://{REDIS_AUTH}{REDIS_HOST}:{REDIS_PORT}"
# Redis URLs
REDIS_CELERY_URL = f"{REDIS_BASE_URL}/{REDIS_CELERY_DB}{REDIS_URL_PARAMS}"
REDIS_CACHE_URL = f"{REDIS_BASE_URL}/{REDIS_DB}{REDIS_URL_PARAMS}"

## Cache config
##
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": REDIS_CACHE_URL,
}
DATA_CACHE_CONFIG = CACHE_CONFIG

## Results backend
##
RESULTS_BACKEND = RedisCache(
    host=REDIS_HOST,
    password=REDIS_PASSWORD,
    port=REDIS_PORT,
    key_prefix='superset_results',
    ssl=REDIS_TLS_ENABLED,
    ssl_cert_reqs=REDIS_SSL_CERT_REQS,
)

## Celery config
##
class CeleryConfig:
    imports  = ("superset.sql_lab", )
    broker_url = REDIS_CELERY_URL
    result_backend = REDIS_CELERY_URL

CELERY_CONFIG = CeleryConfig

## Load user extended config
##
try:
    import superset_config_docker
    from superset_config_docker import *  # noqa

    logger.info(
        f"Loaded your configuration from " f"[{superset_config_docker.__file__}]"
    )
except ImportError:
    logger.info("Using default settings")


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
GUEST_TOKEN_JWT_SECRET = "${SUPERSET_GUEST_TOKEN}"
# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = False

# Cross Origin Config
# default value
#ENABLE_CORS = True
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'resources':['*'],
    'origins': ["https://superset-${CLUSTER_DOMAIN}"]
}

# Talisman Config
TALISMAN_ENABLED = True
TALISMAN_CONFIG = {
    "content_security_policy": {
        "frame-ancestors": ["https://superset-${CLUSTER_DOMAIN}"]
    },
    "force_https": False,
    "force_https_permanent": False,
    "frame_options": "ALLOWFROM",
    "frame_options_allow_from": "*"
}