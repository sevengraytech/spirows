# ─────────────────────────────────────────────────────────────────────────────
# Evilginx Web UI Configuration
# ─────────────────────────────────────────────────────────────────────────────

import os
from pathlib import Path

# Base paths
BASE_DIR = Path(__file__).parent
CONFIG_DIR = Path(os.environ.get("EVILGINX_CONFIG_DIR", "/config"))
PHISHLETS_DIR = CONFIG_DIR / "phishlets"
CERTS_DIR = CONFIG_DIR / "certs"
LOGS_DIR = CONFIG_DIR / "logs"
EVILGINX_CONFIG_FILE = CONFIG_DIR / "config.json"

# UI settings
SECRET_KEY = os.environ.get("UI_SECRET_KEY", "change-me-in-production")
UI_HOST = os.environ.get("UI_HOST", "0.0.0.0")
UI_PORT = int(os.environ.get("UI_PORT", "5000"))

# Authentication
UI_USERNAME = os.environ.get("UI_USERNAME", "admin")
UI_PASSWORD = os.environ.get("UI_PASSWORD", "change-me-in-production")

# Evilginx binary
EVILGINX_BIN = "/usr/local/bin/evilginx"

# Phishlet metadata
PHISHLET_INFO = {
    "amazon": {"name": "Amazon", "category": "E-commerce"},
    "citrix": {"name": "Citrix", "category": "VPN/Remote Access"},
    "facebook": {"name": "Facebook", "category": "Social Media"},
    "github": {"name": "GitHub", "category": "Development"},
    "instagram": {"name": "Instagram", "category": "Social Media"},
    "linkedin": {"name": "LinkedIn", "category": "Professional"},
    "o365": {"name": "Office 365", "category": "Enterprise"},
    "okta": {"name": "Okta", "category": "Identity"},
    "onelogin": {"name": "OneLogin", "category": "Identity"},
    "outlook": {"name": "Outlook", "category": "Email"},
    "protonmail": {"name": "ProtonMail", "category": "Email"},
    "reddit": {"name": "Reddit", "category": "Social Media"},
    "twitter": {"name": "Twitter/X", "category": "Social Media"},
    "twitter-mobile": {"name": "Twitter Mobile", "category": "Social Media"},
    "wordpress.org": {"name": "WordPress.org", "category": "CMS"},
}