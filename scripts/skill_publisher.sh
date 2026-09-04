#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  skill_publisher.sh validate <skill-directory>
  skill_publisher.sh install <skill-directory> [--targets all|codex,kimi,qoder,trae] [--force] [--dry-run]
  skill_publisher.sh package <skill-directory> [--output-dir <directory>]
  skill_publisher.sh publish <distribution-project> [--repo <owner/name>] [--public] [--email <email>]
EOF
}

frontmatter_name() {
  awk '
    NR == 1 { front = 1; next }
    front && /^---[[:space:]]*$/ { exit }
    front && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' "$1/SKILL.md"
}

validate_skill() {
  [ "$#" -eq 1 ] || die "validate requires one skill directory"
  local dir=$1 file name description folder unsafe
  [ -d "$dir" ] || die "skill directory does not exist: $dir"
  dir=$(cd "$dir" && pwd -P)
  file="$dir/SKILL.md"
  [ -f "$file" ] || die "missing SKILL.md"
  [ "$(sed -n '1p' "$file")" = "---" ] || die "SKILL.md must start with YAML frontmatter"

  name=$(frontmatter_name "$dir")
  [ -n "$name" ] || die "frontmatter name is missing"
  printf '%s\n' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || die "invalid skill name: $name"
  description=$(awk '
    NR == 1 { front = 1; next }
    front && /^---[[:space:]]*$/ { exit }
    front && /^description:[[:space:]]*/ { print; exit }
  ' "$file")
  [ -n "$description" ] || die "frontmatter description is missing"

  folder=$(basename "$dir")
  [ "$folder" = "$name" ] || die "folder '$folder' does not match name '$name'"
  ! grep -nE '\[TODO|TODO:' "$file" >/dev/null 2>&1 || die "SKILL.md contains TODO placeholders"
  ! find "$dir" -type l -print -quit | grep -q . || die "symbolic links are not distributable"

  unsafe=$(find "$dir" \
    \( -name .git -o -name .plugin-eval -o -name __pycache__ -o -name .DS_Store \
       -o -name .env -o -name auth.json -o -name credentials.json \
       -o -name '*.pem' -o -name '*.key' \) -print -quit)
  [ -z "$unsafe" ] || die "unsafe or transient file found: $unsafe"

  if [ -f "$dir/agents/openai.yaml" ]; then
    grep -Eq '^[[:space:]]*default_prompt:' "$dir/agents/openai.yaml" ||
      die "agents/openai.yaml is missing default_prompt"
  fi
  echo "VALID: name=$name path=$dir"
}

target_root() {
  case "$1" in
    codex) echo "${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}" ;;
    kimi) echo "${KIMI_SKILLS_DIR:-${KIMI_HOME:-$HOME/.kimi}/skills}" ;;
    qoder) echo "${QODER_SKILLS_DIR:-${QODER_HOME:-$HOME/.qoder}/skills}" ;;
    trae) echo "${TRAE_SKILLS_DIR:-${TRAE_HOME:-$HOME/.trae}/skills}" ;;
    *) return 1 ;;
  esac
}

install_skill() {
  [ "$#" -ge 1 ] || die "install requires a skill directory"
  local source=$1 targets=all force=0 dry=0 platform root dest conflict=0 backup name stamp
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --targets) [ "$#" -ge 2 ] || die "--targets needs a value"; targets=$2; shift 2 ;;
      --force) force=1; shift ;;
      --dry-run) dry=1; shift ;;
      *) die "unknown install option: $1" ;;
    esac
  done

  validate_skill "$source"
  source=$(cd "$source" && pwd -P)
  name=$(frontmatter_name "$source")
  [ "$targets" = all ] && targets="codex kimi qoder trae" || targets=$(echo "$targets" | tr ',' ' ')

  for platform in $targets; do
    root=$(target_root "$platform") || die "unsupported target: $platform"
    dest="$root/$name"
    if [ -d "$dest" ] && ! diff -qr "$source" "$dest" >/dev/null 2>&1 && [ "$force" -eq 0 ]; then
      echo "CONFLICT: $platform $dest" >&2
      conflict=1
    elif [ -e "$dest" ] && [ ! -d "$dest" ]; then
      die "destination is not a directory: $dest"
    fi
  done
  [ "$conflict" -eq 0 ] || die "no changes made; confirm overwrite before using --force"

  stamp=$(date '+%Y%m%d-%H%M%S')
  for platform in $targets; do
    root=$(target_root "$platform")
    dest="$root/$name"
    if [ -d "$dest" ] && diff -qr "$source" "$dest" >/dev/null 2>&1; then
      echo "ALREADY: $platform $dest"
      continue
    fi
    if [ "$dry" -eq 1 ]; then
      [ -d "$dest" ] && echo "WOULD BACK UP: $dest"
      echo "WOULD INSTALL: $platform $dest"
      continue
    fi
    mkdir -p "$root"
    if [ -d "$dest" ]; then
      backup="${dest}.backup-${stamp}-$$"
      rsync -a "$dest/" "$backup/"
      echo "BACKUP: $platform $backup"
    fi
    rsync -a --delete "$source/" "$dest/"
    validate_skill "$dest" >/dev/null
    diff -qr "$source" "$dest" >/dev/null 2>&1 || die "verification failed: $platform"
    echo "INSTALLED: $platform $dest"
  done
  echo "Restart or reload the selected applications."
}

package_skill() {
  [ "$#" -ge 1 ] || die "package requires a skill directory"
  local source=$1 output=dist name stamp project_name project zip_path script
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output-dir) [ "$#" -ge 2 ] || die "--output-dir needs a value"; output=$2; shift 2 ;;
      *) die "unknown package option: $1" ;;
    esac
  done

  validate_skill "$source"
  source=$(cd "$source" && pwd -P)
  name=$(frontmatter_name "$source")
  mkdir -p "$output"
  output=$(cd "$output" && pwd -P)
  stamp=$(date '+%Y%m%d-%H%M%S')
  project_name="${name}-skill-project-${stamp}-$$"
  project="$output/$project_name"
  zip_path="$output/$project_name.zip"
  script=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")

  mkdir -p "$project/skills/$name" "$project/scripts"
  rsync -a "$source/" "$project/skills/$name/"
  cp "$script" "$project/scripts/"
  cat > "$project/install.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
root=\$(cd "\$(dirname "\$0")" && pwd -P)
bash "\$root/scripts/skill_publisher.sh" install "\$root/skills/$name" "\$@"
EOF
  chmod +x "$project/install.sh" "$project/scripts/skill_publisher.sh"
  cat > "$project/README.md" <<EOF
# $name

Install the same canonical Skill into Codex, Kimi, Qoder, and Trae:

\`\`\`bash
bash install.sh --targets all
\`\`\`

Different existing copies are not overwritten. Use \`--force\` only after confirming backup and replacement.
EOF
  printf '.DS_Store\n__pycache__/\n.plugin-eval/\n*.log\n' > "$project/.gitignore"
  (
    cd "$project"
    find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort |
      while IFS= read -r file; do shasum -a 256 "$file"; done > SHA256SUMS
  )
  (cd "$output" && zip -qr "$zip_path" "$project_name")
  echo "PROJECT: $project"
  echo "ZIP: $zip_path"
}

publish_project() {
  [ "$#" -ge 1 ] || die "publish requires a distribution project"
  local project=$1 repo= visibility=private email=${GIT_AUTHOR_EMAIL:-1300893414@qq.com}
  local owner first
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --repo) [ "$#" -ge 2 ] || die "--repo needs a value"; repo=$2; shift 2 ;;
      --public) visibility=public; shift ;;
      --email) [ "$#" -ge 2 ] || die "--email needs a value"; email=$2; shift 2 ;;
      *) die "unknown publish option: $1" ;;
    esac
  done

  [ -f "$project/README.md" ] && [ -f "$project/install.sh" ] && [ -d "$project/skills" ] ||
    die "not a generated distribution project: $project"
  project=$(cd "$project" && pwd -P)
  command -v gh >/dev/null 2>&1 || die "gh is not installed"
  command -v git >/dev/null 2>&1 || die "git is not installed"
  gh auth status >/dev/null
  if [ -z "$repo" ]; then
    owner=$(gh api user --jq .login)
    first=$(find "$project/skills" -mindepth 1 -maxdepth 1 -type d -print | LC_ALL=C sort | sed -n '1p')
    [ -n "$first" ] || die "no Skill found in project"
    repo="$owner/$(basename "$first")-skill"
  fi
  ! gh repo view "$repo" >/dev/null 2>&1 || die "repository already exists: $repo"
  if [ -d "$project/.git" ] && [ -n "$(git -C "$project" remote)" ]; then
    die "project already has Git remotes"
  fi
  git -C "$project" init
  git -C "$project" branch -M main
  git -C "$project" config user.email "$email"
  git -C "$project" config user.name "Skill Publisher"
  git -C "$project" add .
  git -C "$project" commit -m "Publish Skill distribution"
  if [ "$visibility" = public ]; then
    gh repo create "$repo" --public --source "$project" --remote origin --push
  else
    gh repo create "$repo" --private --source "$project" --remote origin --push
  fi
  gh repo view "$repo" --json nameWithOwner,url,isPrivate,defaultBranchRef
}

[ "$#" -ge 1 ] || { usage; exit 2; }
command=$1
shift
case "$command" in
  validate) validate_skill "$@" ;;
  install) install_skill "$@" ;;
  package) package_skill "$@" ;;
  publish) publish_project "$@" ;;
  -h|--help|help) usage ;;
  *) usage; die "unknown command: $command" ;;
esac
