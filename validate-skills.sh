#!/usr/bin/env bash
# Validate every skill in skills/ against the Agent Skills spec.
# Checks: YAML frontmatter, required fields, name matches folder, description length,
# file size, and standard folder structure.

set -u

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
PASS=0
WARN=0
FAIL=0
SKILL_COUNT=0

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

err()  { printf "  ${RED}x${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${YELLOW}!${NC} %s\n" "$1"; WARN=$((WARN+1)); }
ok()   { printf "  ${GREEN}v${NC} %s\n" "$1"; PASS=$((PASS+1)); }

printf "${CYAN}Validating skills in %s${NC}\n\n" "$SKILLS_DIR"

if [[ ! -d "$SKILLS_DIR" ]]; then
  printf "${RED}skills/ folder not found.${NC}\n"
  exit 1
fi

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  SKILL_COUNT=$((SKILL_COUNT+1))
  skill_name="$(basename "$skill_dir")"
  skill_md="${skill_dir}SKILL.md"

  printf "${CYAN}%s${NC}\n" "$skill_name"

  # SKILL.md exists
  if [[ ! -f "$skill_md" ]]; then
    err "SKILL.md missing"
    continue
  fi

  # Folder name format
  if [[ ! "$skill_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    err "folder name must be lowercase alphanumeric with hyphens"
  else
    ok "folder name valid"
  fi

  # Frontmatter present
  first_line="$(head -n1 "$skill_md")"
  if [[ "$first_line" != "---" ]]; then
    err "SKILL.md must start with YAML frontmatter (---)"
    continue
  fi

  # Extract frontmatter (between the first two --- delimiters)
  frontmatter="$(awk '/^---[[:space:]]*$/{n++; next} n==1{print} n==2{exit}' "$skill_md")"

  # name field
  yaml_name="$(printf "%s" "$frontmatter" | awk -F': ' '/^name:/{print $2; exit}' | tr -d '"' | tr -d "'" | tr -d '[:space:]')"
  if [[ -z "$yaml_name" ]]; then
    err "name field missing from frontmatter"
  elif [[ "$yaml_name" != "$skill_name" ]]; then
    err "name '$yaml_name' does not match folder '$skill_name'"
  else
    ok "name matches folder"
  fi

  if [[ ${#yaml_name} -gt 64 ]]; then
    err "name exceeds 64 characters"
  fi

  # description field — parse only the frontmatter we already extracted (not the body)
  desc_block="$(printf "%s\n" "$frontmatter" | awk '
    BEGIN{in_desc=0}
    /^description:/{
      sub(/^description:[ \t]*/, "")
      if ($0 ~ /^>/ || $0 ~ /^\|/) { in_desc=1; next }
      print; exit
    }
    in_desc==1 {
      if ($0 ~ /^[a-zA-Z_-]+:/) exit
      sub(/^[ \t]+/, "")
      printf "%s ", $0
    }
  ')"

  desc_len=${#desc_block}
  if [[ $desc_len -eq 0 ]]; then
    err "description field missing or empty"
  elif [[ $desc_len -gt 1024 ]]; then
    warn "description is $desc_len chars, consider trimming under 1024"
  else
    ok "description present ($desc_len chars)"
  fi

  # Trigger phrase hint
  if [[ "$desc_block" == *"when"* || "$desc_block" == *"Use"* || "$desc_block" == *"use"* ]]; then
    ok "description has trigger phrasing"
  else
    warn "description should include 'use' or 'when' trigger phrasing"
  fi

  # File size
  line_count=$(wc -l < "$skill_md" | tr -d '[:space:]')
  if [[ $line_count -gt 500 ]]; then
    warn "SKILL.md is $line_count lines, consider moving detail to references/"
  else
    ok "SKILL.md size OK ($line_count lines)"
  fi

  # Optional standard folders
  for sub in references scripts assets; do
    if [[ -d "${skill_dir}${sub}" ]]; then
      ok "has ${sub}/ folder"
    fi
  done

  printf "\n"
done

# ---------------------------------------------------------------------------
# Trigger-phrase collision check
#
# Two skills that advertise the same quoted trigger phrase compete for the same
# user sentence, and the agent has to guess. This pass flags those overlaps
# inside skills/, and — when EXTERNAL_SKILLS_DIR is set — against skills you
# already have installed from other packs. Example:
#
#   EXTERNAL_SKILLS_DIR=~/.claude/plugins ./validate-skills.sh
#
# Overlaps are warnings, not failures: sometimes you want two skills to share a
# phrase and disambiguate in the body. Fix the ones you did not intend.
# ---------------------------------------------------------------------------

PHRASE_TMP="$(mktemp)"
DESC_TMP="$(mktemp)"
trap 'rm -f "$PHRASE_TMP" "$DESC_TMP"' EXIT

# Emit "phrase<TAB>label" for every quoted trigger phrase of >= 9 chars found in
# a SKILL.md frontmatter description.
collect_phrases() {
  local root="$1" label_prefix="$2"
  while IFS= read -r md; do
    local sname front desc label
    sname="$(basename "$(dirname "$md")")"
    label="${label_prefix}${sname}"
    front="$(awk '/^---[[:space:]]*$/{n++; next} n==1{print} n==2{exit}' "$md")"
    desc="$(printf "%s\n" "$front" | awk '
      BEGIN{d=0}
      /^description:/{sub(/^description:[ \t]*[>|][-+]?[ \t]*$/,""); sub(/^description:[ \t]*/,""); d=1; print; next}
      d==1{ if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:[ \t]/) exit; sub(/^[ \t]+/,""); print }
    ')"
    # A YAML description may itself be wrapped in quotes. Drop that outer pair,
    # otherwise the scanner below reads the whole description as one phrase and
    # never sees the trigger phrases quoted inside it.
    desc="${desc#[\"\']}"
    desc="${desc%[\"\']}"

    # Scan for quoted trigger phrases. Double quotes are unambiguous; single
    # quotes only count when the opening quote follows a non-word character and
    # the closing quote is followed by one, so apostrophes in "the user's post"
    # are not mistaken for a quoted phrase.
    printf "%s" "$desc" | awk '
      function emit(p) {
        gsub(/^[ \t]+|[ \t]+$/, "", p)
        gsub(/[ \t]+/, " ", p)
        sub(/[,.;:!?]+$/, "", p)
        if (length(p) >= 9 && length(p) <= 60) print tolower(p)
      }
      {
        line = $0
        n = length(line)
        for (i = 1; i <= n; i++) {
          c = substr(line, i, 1)
          if (c == "\"") {
            j = index(substr(line, i + 1), "\"")
            if (j > 0) { emit(substr(line, i + 1, j - 1)); i = i + j }
          } else if (c == "'"'"'") {
            prev = (i == 1) ? " " : substr(line, i - 1, 1)
            if (prev ~ /[A-Za-z0-9]/) continue
            j = index(substr(line, i + 1), "'"'"'")
            if (j > 0) {
              nxt = substr(line, i + j + 1, 1)
              if (nxt == "" || nxt !~ /[A-Za-z0-9]/) { emit(substr(line, i + 1, j - 1)); i = i + j }
            }
          }
        }
      }
    ' | while IFS= read -r phrase; do
          [[ -n "$phrase" ]] && printf "%s\t%s\n" "$phrase" "$label"
        done

    # One flat, lowercased line per skill, for the substring pass below.
    printf "%s\t%s\n" "$label" \
      "$(printf "%s" "$desc" | tr '\n' ' ' | tr '[:upper:]' '[:lower:]' | tr -d '"'"'"'"' | sed 's/[[:space:]]\{1,\}/ /g')" \
      >> "$DESC_TMP"
  done < <(find "$root" -name SKILL.md -type f 2>/dev/null)
}

collect_phrases "$SKILLS_DIR" "" > "$PHRASE_TMP"

if [[ -n "${EXTERNAL_SKILLS_DIR:-}" ]]; then
  if [[ -d "${EXTERNAL_SKILLS_DIR}" ]]; then
    collect_phrases "${EXTERNAL_SKILLS_DIR}" "external:" >> "$PHRASE_TMP"
  else
    warn "EXTERNAL_SKILLS_DIR '${EXTERNAL_SKILLS_DIR}' is not a directory, skipping external check"
  fi
fi

printf "${CYAN}Trigger-phrase collisions${NC}\n"

COLLISIONS=0
while IFS=$'\t' read -r phrase owners; do
  [[ -z "$phrase" ]] && continue
  COLLISIONS=$((COLLISIONS+1))
  printf "  ${YELLOW}!${NC} %s -> %s\n" "\"$phrase\"" "$owners"
  WARN=$((WARN+1))
done < <(
  sort -u "$PHRASE_TMP" \
  | awk -F'\t' '{ if ($1 in a) a[$1]=a[$1]", "$2; else a[$1]=$2; n[$1]++ }
                END { for (p in n) if (n[p] > 1) printf "%s\t%s\n", p, a[p] }' \
  | sort
)

# Softer pass: a trigger phrase one skill advertises also appears verbatim in
# another skill's description. The agent sees both as candidates for the same
# sentence even though the phrase lists are not identical. Only pairs involving
# a skill from this repo are reported.
while IFS=$'\t' read -r phrase pair; do
  [[ -z "$phrase" ]] && continue
  COLLISIONS=$((COLLISIONS+1))
  printf "  ${YELLOW}!${NC} %s -> %s\n" "\"$phrase\"" "$pair"
  WARN=$((WARN+1))
done < <(
  awk -F'\t' '
    NR==FNR { desc[$1] = $2; next }
    {
      phrase = $1; owner = $2
      if (seen[phrase SUBSEP owner]++) next
      for (label in desc) {
        if (label == owner) continue
        if (index(desc[label], phrase) == 0) continue
        # skip when both sides already advertise the phrase (exact pass covers it)
        key = phrase SUBSEP label
        if (key in owners) continue
        if (owner ~ /^external:/ && label ~ /^external:/) continue
        a = owner; b = label
        if (a > b) { t = a; a = b; b = t }
        pairkey = phrase SUBSEP a SUBSEP b
        if (pairkey in printed) continue
        printed[pairkey] = 1
        printf "%s\t%s, %s\n", phrase, a, b
      }
    }
  ' "$DESC_TMP" <(awk -F'\t' '{print $1"\t"$2}' "$PHRASE_TMP" | sort -u) | sort -u
)

if [[ $COLLISIONS -eq 0 ]]; then
  printf "  ${GREEN}v${NC} no shared trigger phrases\n"
fi
printf "\n"

printf "${CYAN}Summary${NC}\n"
printf "  Skills checked: %d\n" "$SKILL_COUNT"
printf "  ${GREEN}Passed:${NC}   %d\n" "$PASS"
printf "  ${YELLOW}Warnings:${NC} %d\n" "$WARN"
printf "  ${RED}Failed:${NC}   %d\n" "$FAIL"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
