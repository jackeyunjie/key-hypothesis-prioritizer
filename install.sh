#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd -P)
bash "$root/scripts/skill_publisher.sh" install "$root/skills/key-hypothesis-prioritizer" "$@"
