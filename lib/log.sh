# Logger: colored, categorized log lines on stderr.

use_color() {
  [[ -t 2 && -z "${NO_COLOR:-}" ]]
}

level_escape() {
  case "$1" in
    INFO) printf '\033[32m' ;;
    WARN) printf '\033[33m' ;;
    ERROR) printf '\033[31m' ;;
  esac
}

# FNV-1a 32-bit hash of a string.
fnv1a_hash() {
  local text=$1
  local hash=2166136261
  local i byte
  for (( i = 0; i < ${#text}; i++ )); do
    printf -v byte '%d' "'${text:i:1}"
    hash=$(( ((hash ^ byte) * 16777619) & 0xFFFFFFFF ))
  done
  printf '%d\n' "$hash"
}

# HSL to RGB on a 0-1000 scale. Input: hue (0-359). Saturation 60%, lightness 80%.
# Prints "R G B" (0-255).
hsl_to_rgb() {
  local hue=$1
  local saturation=600
  local lightness=800
  local span chroma offset x m r1 g1 b1

  span=$(( 2 * lightness - 1000 ))
  if (( span < 0 )); then span=$(( -span )); fi
  chroma=$(( (1000 - span) * saturation / 1000 ))

  offset=$(( hue % 120 - 60 ))
  if (( offset < 0 )); then offset=$(( -offset )); fi
  x=$(( chroma * (60 - offset) / 60 ))
  m=$(( lightness - chroma / 2 ))

  case $(( hue / 60 )) in
    0) r1=$chroma g1=$x b1=0 ;;
    1) r1=$x g1=$chroma b1=0 ;;
    2) r1=0 g1=$chroma b1=$x ;;
    3) r1=0 g1=$x b1=$chroma ;;
    4) r1=$x g1=0 b1=$chroma ;;
    *) r1=$chroma g1=0 b1=$x ;;
  esac

  printf '%d %d %d\n' \
    $(( (r1 + m) * 255 / 1000 )) \
    $(( (g1 + m) * 255 / 1000 )) \
    $(( (b1 + m) * 255 / 1000 ))
}

# Stable pastel color for a category, as a 24-bit ANSI escape.
category_escape() {
  local hue rgb r g b
  hue=$(( $(fnv1a_hash "$1") % 360 ))
  rgb=$(hsl_to_rgb "$hue")
  read -r r g b <<<"$rgb"
  printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

log_emit() {
  local level=$1 category=$2 message=$3
  local timestamp level_code="" category_code="" reset=""

  # LC_ALL=C keeps the Gregorian year on Buddhist-calendar locales.
  timestamp=$(LC_ALL=C date '+%F %T')
  if use_color; then
    level_code=$(level_escape "$level")
    category_code=$(category_escape "$category")
    reset=$'\033[0m'
  fi
  printf '%s %s%s%s %s[%s]%s %s\n' \
    "$timestamp" "$level_code" "$level" "$reset" \
    "$category_code" "$category" "$reset" "$message" >&2
}

log_info() { log_emit INFO "$1" "$2"; }
log_warn() { log_emit WARN "$1" "$2"; }
log_error() { log_emit ERROR "$1" "$2"; }
