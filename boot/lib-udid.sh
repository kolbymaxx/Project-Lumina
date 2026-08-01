# Shared UDID helpers for Lumina boot/SSH scripts.
# shellcheck shell=bash

# This research XR (n841ap). Never use the foreign hsbugss sample UDID.
LUMINA_XR_UDID="00008020-00117540340B002E"
LUMINA_FOREIGN_SAMPLE_UDID="00008020-000231A00EE9002E"

lumina_warn_foreign_udid() {
  local candidate="$1"
  if [[ "$candidate" == "$LUMINA_FOREIGN_SAMPLE_UDID" ]]; then
    echo "error: refusing foreign sample UDID ${candidate}" >&2
    echo "use ${LUMINA_XR_UDID}, LUMINA_UDID=any, or idevice_id auto-detect" >&2
    return 1
  fi
  return 0
}

# Resolve LUMINA_UDID:
# 1) explicit env/config value (unless foreign sample)
# 2) single connected usbmux device via idevice_id
# 3) this XR's UDID
lumina_resolve_udid() {
  local idevice_id_cmd="${IDEVICE_ID:-idevice_id}"
  local explicit="${LUMINA_UDID:-}"
  local ids
  local count

  if [[ -n "$explicit" ]]; then
    if [[ "$explicit" != "any" ]]; then
      lumina_warn_foreign_udid "$explicit" || return 1
    fi
    printf '%s\n' "$explicit"
    return 0
  fi

  if command -v "$idevice_id_cmd" >/dev/null 2>&1; then
    ids="$("$idevice_id_cmd" -l 2>/dev/null || true)"
    if [[ -n "$ids" ]]; then
      count="$(printf '%s\n' "$ids" | sed '/^$/d' | wc -l | tr -d ' ')"
      if [[ "$count" == "1" ]]; then
        printf '%s\n' "$(printf '%s\n' "$ids" | sed '/^$/d' | head -n1)"
        return 0
      fi
    fi
  fi

  printf '%s\n' "$LUMINA_XR_UDID"
}
