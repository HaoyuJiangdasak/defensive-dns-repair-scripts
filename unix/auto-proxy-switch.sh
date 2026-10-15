#!/usr/bin/env bash
set -euo pipefail

# Detect a local HTTP proxy and keep Git's global proxy settings consistent.
# Override these values through the environment when needed.
PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
PROXY_TEST_URL="${PROXY_TEST_URL:-https://example.com}"

check_proxy() {
    curl --silent --show-error --connect-timeout 2 --max-time 5 \
        --proxy "$PROXY_URL" "$PROXY_TEST_URL" >/dev/null
}

current_proxy() {
    git config --global --get http.proxy 2>/dev/null || true
}

enable_proxy() {
    git config --global http.proxy "$PROXY_URL"
    git config --global https.proxy "$PROXY_URL"
    printf '[%s] Git proxy enabled: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PROXY_URL"
}

disable_proxy() {
    git config --global --unset http.proxy 2>/dev/null || true
    git config --global --unset https.proxy 2>/dev/null || true
    printf '[%s] Git proxy disabled (direct connection)\n' "$(date '+%Y-%m-%d %H:%M:%S')"
}

if check_proxy; then
    if [[ -z "$(current_proxy)" ]]; then
        enable_proxy
    else
        printf '[%s] Proxy already configured: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PROXY_URL"
    fi
else
    if [[ -n "$(current_proxy)" ]]; then
        disable_proxy
    else
        printf '[%s] Direct connection already configured\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    fi
fi
