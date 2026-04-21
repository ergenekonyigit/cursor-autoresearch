#!/usr/bin/env bash
# Install Cursor rules and/or agent skills from cursor-autoresearch into any project.
#
# From your project root (copy-paste from README):
#   curl -fsSL https://raw.githubusercontent.com/ergenekonyigit/cursor-autoresearch/main/scripts/add-to-your-project.sh | bash -s -- --all
#
# Env:
#   TARGET              — project directory (default: current working directory)
#   REF                 — git ref on GitHub (default: main)
#   REPO_SLUG           — owner/repo for raw.githubusercontent.com (default: ergenekonyigit/cursor-autoresearch)
#   AUTORESEARCH_ROOT   — local clone path; when set and valid, read files from disk instead of curl
#
# Flags (after bash -s -- when piping):
#   --rules   — install .cursor/rules/autoresearch-active.mdc
#   --skills  — install skills under .cursor/skills/ (workspace-local)
#   --all     — rules + skills (default when no component flag is passed)
#   --symlink — symlink into AUTORESEARCH_ROOT instead of copying (requires AUTORESEARCH_ROOT)

set -euo pipefail

REF="${REF:-main}"
REPO_SLUG="${REPO_SLUG:-ergenekonyigit/cursor-autoresearch}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${REF}"

TARGET="${TARGET:-$(pwd)}"
DO_RULES=0
DO_SKILLS=0
USE_SYMLINK=0

usage() {
  cat >&2 <<'EOF'
Usage:
  add-to-your-project.sh [TARGET_DIR] [--rules] [--skills] [--all] [--symlink]

Examples:
  curl -fsSL .../add-to-your-project.sh | bash -s -- --all
  TARGET="$HOME/work/my-app" curl -fsSL .../add-to-your-project.sh | bash -s -- --rules
  AUTORESEARCH_ROOT="$HOME/dev/cursor-autoresearch" ./add-to-your-project.sh . --all --symlink
EOF
}

fatal() {
  echo "error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "$1 is required."
}

fetch_file() {
  local rel="$1"
  local dest="$2"
  mkdir -p "$(dirname "${dest}")"
  if [[ "${USE_LOCAL}" -eq 1 ]]; then
    local src="${LOCAL_ROOT}/${rel}"
    [[ -f "${src}" ]] || fatal "missing file in clone: ${src}"
    cp -f "${src}" "${dest}"
  else
    require_cmd curl
    curl -fsSL "${RAW_BASE}/${rel}" -o "${dest}"
  fi
}

link_tree() {
  local name="$1"
  local dest_dir="${TARGET}/.cursor/skills/${name}"
  local src_dir="${LOCAL_ROOT}/skills/${name}"
  [[ -d "${src_dir}" ]] || fatal "missing skill in clone: ${src_dir}"
  mkdir -p "$(dirname "${dest_dir}")"
  rm -rf "${dest_dir}"
  ln -sfn "${src_dir}" "${dest_dir}"
}

copy_skill_dir() {
  local name="$1"
  local dest_dir="${TARGET}/.cursor/skills/${name}"
  mkdir -p "${dest_dir}"
  fetch_file "skills/${name}/SKILL.md" "${dest_dir}/SKILL.md"
}

install_rules() {
  mkdir -p "${TARGET}/.cursor/rules"
  if [[ "${USE_SYMLINK}" -eq 1 ]]; then
    local src="${LOCAL_ROOT}/.cursor/rules/autoresearch-active.mdc"
    [[ -f "${src}" ]] || fatal "missing rule in clone: ${src}"
    ln -sfn "${src}" "${TARGET}/.cursor/rules/autoresearch-active.mdc"
  else
    fetch_file ".cursor/rules/autoresearch-active.mdc" "${TARGET}/.cursor/rules/autoresearch-active.mdc"
  fi
  echo "==> rule installed: ${TARGET}/.cursor/rules/autoresearch-active.mdc"
}

install_skills() {
  mkdir -p "${TARGET}/.cursor/skills"
  for name in autoresearch-create autoresearch-finalize; do
    if [[ "${USE_SYMLINK}" -eq 1 ]]; then
      link_tree "${name}"
    else
      copy_skill_dir "${name}"
    fi
    echo "==> skill installed: ${TARGET}/.cursor/skills/${name}"
  done
}

LOCAL_ROOT="${AUTORESEARCH_ROOT:-}"
USE_LOCAL=0
if [[ -n "${LOCAL_ROOT}" ]]; then
  LOCAL_ROOT="$(cd "${LOCAL_ROOT}" && pwd)"
  if [[ -f "${LOCAL_ROOT}/package.json" ]] && grep -q '"name": "cursor-autoresearch"' "${LOCAL_ROOT}/package.json" 2>/dev/null; then
    USE_LOCAL=1
  else
    fatal "AUTORESEARCH_ROOT does not look like the cursor-autoresearch repo root: ${LOCAL_ROOT}"
  fi
fi

positional_target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --rules) DO_RULES=1 ;;
    --skills) DO_SKILLS=1 ;;
    --all)
      DO_RULES=1
      DO_SKILLS=1
      ;;
    --symlink) USE_SYMLINK=1 ;;
    -*)
      usage
      fatal "unknown option: $1"
      ;;
    *)
      if [[ -n "${positional_target}" ]]; then
        fatal "unexpected extra argument: $1"
      fi
      positional_target="$1"
      ;;
  esac
  shift
done

if [[ -n "${positional_target}" ]]; then
  TARGET="$(cd "${positional_target}" && pwd)"
fi

TARGET="$(cd "${TARGET}" && pwd)"

if [[ "${DO_RULES}" -eq 0 && "${DO_SKILLS}" -eq 0 ]]; then
  DO_RULES=1
  DO_SKILLS=1
fi

if [[ "${USE_SYMLINK}" -eq 1 ]]; then
  [[ "${USE_LOCAL}" -eq 1 ]] || fatal "--symlink requires AUTORESEARCH_ROOT to point at a local cursor-autoresearch clone."
fi

if [[ "${USE_SYMLINK}" -eq 0 && "${USE_LOCAL}" -eq 1 ]]; then
  : # Local root without symlink still avoids network: copy from clone.
fi

if [[ "${USE_LOCAL}" -eq 0 && "${USE_SYMLINK}" -eq 1 ]]; then
  fatal "--symlink requires AUTORESEARCH_ROOT."
fi

if [[ "${DO_RULES}" -eq 1 ]]; then
  install_rules
fi
if [[ "${DO_SKILLS}" -eq 1 ]]; then
  install_skills
fi

echo ""
echo "Done. Open the project in Cursor; rules apply from .cursor/rules/ and skills from .cursor/skills/."
