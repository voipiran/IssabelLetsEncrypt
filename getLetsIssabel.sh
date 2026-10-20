#!/bin/bash

set -u

read -r -p "Enter your domain name: " domain

if [ -z "$domain" ]; then
    echo "Domain name is required." >&2
    exit 1
fi

if ! command -v certbot >/dev/null 2>&1; then
    echo "certbot is not installed." >&2
    exit 1
fi

HTTPD_WAS_ACTIVE=0
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet httpd; then
    HTTPD_WAS_ACTIVE=1
    systemctl stop httpd
fi

start_httpd()
{
    if [ "$HTTPD_WAS_ACTIVE" -eq 1 ]; then
        systemctl start httpd
    fi
}

if ! certbot certonly --standalone -d "$domain"; then
    start_httpd
    echo "Let's Encrypt certificate issuance failed." >&2
    exit 1
fi

start_httpd

CERT_DIR="/etc/letsencrypt/live/$domain"
PRIVATE_KEY="$CERT_DIR/privkey.pem"
FULL_CHAIN="$CERT_DIR/fullchain.pem"

if [ ! -r "$PRIVATE_KEY" ] || [ ! -r "$FULL_CHAIN" ]; then
    echo "The issued certificate files were not found in $CERT_DIR." >&2
    exit 1
fi

# Install the certificate in Apache when the Apache plugin is available.
if command -v httpd >/dev/null 2>&1 && certbot plugins 2>/dev/null | grep -q 'apache'; then
    certbot install --cert-name "$domain" --apache || \
        echo "Warning: Apache certificate installation failed." >&2
fi

ASTERISK_CERT="/etc/asterisk/keys/asterisk.pem"
ASTERISK_BACKUP="/etc/asterisk/keys/asterisk-bk-$(date +%Y%m%d%H%M%S).pem"

if [ -f "$ASTERISK_CERT" ]; then
    cp -p "$ASTERISK_CERT" "$ASTERISK_BACKUP"
fi

cat "$PRIVATE_KEY" "$FULL_CHAIN" > "$ASTERISK_CERT"
chown asterisk:asterisk "$ASTERISK_CERT"
chmod 664 "$ASTERISK_CERT"

ASTERISK_TLS_CONFIG="/etc/asterisk/sip_general_custom.conf"
TLS_MARKER="; VOIPIRAN_LETSENCRYPT_TLS"

if ! grep -Fq "$TLS_MARKER" "$ASTERISK_TLS_CONFIG" 2>/dev/null; then
    cat >> "$ASTERISK_TLS_CONFIG" <<EOF

$TLS_MARKER
tlsenable=yes
tlsbindaddr=0.0.0.0
tlscertfile=$ASTERISK_CERT
tlscafile=$ASTERISK_CERT
tlsdontverifyserver=no
tlscipher=ALL
tlsclientmethod=ALL
EOF
fi

systemctl reload asterisk

WEBPHONE_INSTALLER="/var/www/voipiran/installSH/webphone.sh"
if [ -f "$WEBPHONE_INSTALLER" ]; then
    if ! WEBPHONE_DOMAIN="$domain" bash "$WEBPHONE_INSTALLER" update; then
        echo "Warning: WebPhone Nginx configuration failed." >&2
    fi
fi

# Nginx is optional on Issabel. If it exists, validate and reload its current
# configuration so configured virtual hosts use the renewed live certificate.
if command -v nginx >/dev/null 2>&1; then
    if nginx -t; then
        systemctl reload nginx
    else
        echo "Warning: nginx configuration test failed; Nginx was not reloaded." >&2
    fi
fi

RENEWAL_HOOK_DIR="/etc/letsencrypt/renewal-hooks/deploy"
RENEWAL_HOOK="$RENEWAL_HOOK_DIR/voipiran-issabel.sh"
mkdir -p "$RENEWAL_HOOK_DIR"

cat > "$RENEWAL_HOOK" <<'EOF'
#!/bin/bash

set -u

domain="${CERTBOT_DOMAIN:-}"
lineage="${RENEWED_LINEAGE:-/etc/letsencrypt/live/$domain}"

if [ -z "$domain" ] || [ ! -r "$lineage/privkey.pem" ] || [ ! -r "$lineage/fullchain.pem" ]; then
    echo "Renewal hook: certificate lineage is unavailable." >&2
    exit 1
fi

cat "$lineage/privkey.pem" "$lineage/fullchain.pem" > /etc/asterisk/keys/asterisk.pem
chown asterisk:asterisk /etc/asterisk/keys/asterisk.pem
chmod 664 /etc/asterisk/keys/asterisk.pem
systemctl reload asterisk

webphone_installer="/var/www/voipiran/installSH/webphone.sh"
if [ -f "$webphone_installer" ]; then
    WEBPHONE_DOMAIN="$domain" bash "$webphone_installer" update
fi

if command -v nginx >/dev/null 2>&1 && nginx -t; then
    systemctl reload nginx
fi
EOF

chmod 700 "$RENEWAL_HOOK"

echo "Let's Encrypt certificate installed for Asterisk."
if command -v nginx >/dev/null 2>&1; then
    echo "Nginx was detected and reloaded after configuration validation."
else
    echo "Nginx is not installed; Asterisk setup completed without Nginx changes."
fi
echo "Renewal hook installed at $RENEWAL_HOOK."
