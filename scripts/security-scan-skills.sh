#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

shopt -s nocasematch

high_count=0
medium_count=0
low_count=0

# The scanner is intentionally static and conservative. Dangerous tokens inside
# explicit security/forbidden-example sections are treated as documentation,
# unless the line is phrased as an actual instruction to run the dangerous
# action.
DOCUMENTATION_CONTEXT_SECTIONS=(
  "Forbidden Patterns"
  "Allowed Patterns"
  "Safety Policy"
  "Threat Model"
  "Security Checks"
  "Security scan"
  "Review Workflow"
  "Code Attacks"
  "Examples of unsafe commands"
  "Unsafe Examples"
  "Blocked Examples"
  "Safety"
)

# Some skills intentionally document local infrastructure administration
# commands. Medium-only admin tokens in these sections are expected operational
# references, not malicious skill behavior. High-severity rules still apply.
OPERATIONAL_CONTEXT_SECTIONS=(
  "Reference Infrastructure"
  "Vault Infrastructure"
  "Deployment protocol"
  "Updating an existing deployment"
  "Required Information Before Starting"
  "Step "
  "Enable and Reload"
  "Work Protocol"
  "Service"
  "Quick Troubleshooting"
  "System References"
  "References"
  "Scope Guard"
  "Closing Protocol"
  "Frontend + Node.js backend deploy"
)

# shellcheck disable=SC2016
HIGH_RULES=(
  'destructive root/home removal:::rm[[:space:]]+-rf[[:space:]]+(/|~|"?\$HOME"?|\$\{HOME\})'
  'remote script piped to shell:::(curl|wget)[^|]*\|[[:space:]]*(bash|sh)'
  'GitHub auth token exposure:::gh[[:space:]]+auth[[:space:]]+token'
  'SSH secret read:::cat[[:space:]]+~/.ssh'
  'GPG secret read:::cat[[:space:]]+~/.gnupg'
  'environment dump:::\bprintenv\b'
  'world-writable permissions:::chmod[[:space:]]+777'
  'hidden action instruction:::hide[^.]{0,80}(action|change|output|failure)|conceal[^.]{0,80}(action|change|output|failure)'
  'ignore safety policies:::ignore[^.]{0,80}(safety|policy|policies|repository rules|higher-priority)'
  'secret exfiltration:::(upload|send|exfiltrat)[^.]{0,120}(secret|credential|token|password|environment variable|env var)'
  'workflow secret leak:::github actions[^.]{0,120}(leak|exfiltrat|upload|send)[^.]{0,80}secret'
  'validation bypass:::((disable|skip|ignore)[^.]{0,80}(validation|security[[:space:]]+check|security[[:space:]]+checks)|bypass[[:space:]]+(validation|security[[:space:]]+check|security[[:space:]]+checks))'
)

MEDIUM_RULES=(
  'destructive recursive removal:::rm[[:space:]]+-rf'
  'broad delete instruction:::(delete|remove|wipe)[^.]{0,80}(repository content|home directory|user files|unrelated user work|all files)'
  'eval execution:::(^|[;&|`])([[:space:]]*)eval[[:space:]]+'
  'shell command wrapper:::bash[[:space:]]+-c'
  'privilege escalation:::\bsudo\b'
  'env file access:::(cat|read|print|open)[^.]{0,40}\.env\b'
  'shell profile modification:::(\.bashrc|\.zshrc|\.profile|shell startup)'
  'git remote change:::git[[:space:]]+remote[[:space:]]+(set-url|add|remove)'
  'force push:::git[[:space:]]+push[^\n]*(--force|-f)'
  'persistence mechanism:::(cron|crontab|systemd|background process|startup file)'
  'recursive permission change:::(chmod|chown)[[:space:]]+-R'
  'remote script execution:::(downloaded content|remote script)[^.]{0,80}(execute|run|bash|sh|python|node)'
)

collect_files() {
  if command -v rg >/dev/null 2>&1; then
    {
      rg --files "$ROOT_DIR/projects" -g 'SKILL.md' 2>/dev/null || true
      rg --files "$ROOT_DIR/prompts" -g '*.md' 2>/dev/null || true
    } | sort -u
  else
    {
      find "$ROOT_DIR/projects" -name SKILL.md -type f 2>/dev/null || true
      find "$ROOT_DIR/prompts" -name '*.md' -type f 2>/dev/null || true
    } | sort -u
  fi
}

trim_heading() {
  local line="$1"
  line="${line#\#}"
  while [[ "$line" == \#* ]]; do line="${line#\#}"; done
  line="${line# }"
  line="${line%% }"
  printf '%s' "$line"
}

in_documentation_context() {
  local section="$1"
  local item
  for item in "${DOCUMENTATION_CONTEXT_SECTIONS[@]}"; do
    if [[ "$section" == "$item" || "$section" == *"$item"* ]]; then
      return 0
    fi
  done
  return 1
}

in_operational_context() {
  local section="$1"
  local item
  for item in "${OPERATIONAL_CONTEXT_SECTIONS[@]}"; do
    if [[ "$section" == "$item" || "$section" == *"$item"* ]]; then
      return 0
    fi
  done
  return 1
}

clearly_forbidden_example() {
  local line="$1"
  [[ "$line" =~ (do[[:space:]]+not|never|forbidden|blocked|unsafe|avoid|detect|flag|must[[:space:]]+not|should[[:space:]]+not) ]]
}

actual_run_instruction() {
  local line="$1"
  [[ "$line" =~ (run|execute|use|apply|perform)[^.]{0,80} ]] && ! clearly_forbidden_example "$line"
}

allowed_operational_medium() {
  local label="$1"
  local line="$2"
  local section="$3"

  in_operational_context "$section" || return 1

  case "$label" in
    "privilege escalation"|"persistence mechanism")
      return 0
      ;;
    "env file access")
      [[ "$line" =~ EnvironmentFile= ]] && return 0
      ;;
  esac

  return 1
}

emit_finding() {
  local severity="$1"
  local file="$2"
  local line_no="$3"
  local concern="$4"
  local rel="${file#"$ROOT_DIR"/}"
  printf '%-6s %s:%s  %s\n' "$severity" "$rel" "$line_no" "$concern"
  case "$severity" in
    HIGH) high_count=$((high_count + 1)) ;;
    MEDIUM) medium_count=$((medium_count + 1)) ;;
    LOW) low_count=$((low_count + 1)) ;;
  esac
}

scan_line_rules() {
  local file="$1"
  local line_no="$2"
  local line="$3"
  local section="$4"
  local rule label pattern severity

  for rule in "${HIGH_RULES[@]}"; do
    label="${rule%%:::*}"
    pattern="${rule#*:::}"
    if [[ "$line" =~ $pattern ]]; then
      severity="HIGH"
      if in_documentation_context "$section" || clearly_forbidden_example "$line"; then
        if actual_run_instruction "$line"; then
          severity="HIGH"
        else
          return 0
        fi
      fi
      emit_finding "$severity" "$file" "$line_no" "$label"
      return 0
    fi
  done

  for rule in "${MEDIUM_RULES[@]}"; do
    label="${rule%%:::*}"
    pattern="${rule#*:::}"
    if [[ "$line" =~ $pattern ]]; then
      severity="MEDIUM"
      if in_documentation_context "$section" || clearly_forbidden_example "$line"; then
        return 0
      fi
      if allowed_operational_medium "$label" "$line" "$section"; then
        return 0
      fi
      emit_finding "$severity" "$file" "$line_no" "$label"
      return 0
    fi
  done
}

scan_file() {
  local file="$1"
  local line_no=0
  local section=""
  local line

  # shellcheck disable=SC2094
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    if [[ "$line" =~ ^##+[[:space:]]+ ]]; then
      section="$(trim_heading "$line")"
    fi
    scan_line_rules "$file" "$line_no" "$line" "$section"
  done < "$file"
}

echo "Security scan: scanning skills and prompts..."

mapfile -t files < <(collect_files)
if [[ "${#files[@]}" -eq 0 ]]; then
  echo "Security scan failed: no skills or prompts found." >&2
  exit 1
fi

for file in "${files[@]}"; do
  scan_file "$file"
done

if [[ "$high_count" -gt 0 ]]; then
  echo "Security scan failed: HIGH severity findings found."
  exit 1
fi

if [[ "$medium_count" -gt 0 || "$low_count" -gt 0 ]]; then
  echo "Security scan completed with warnings."
else
  echo "Security scan OK."
fi
