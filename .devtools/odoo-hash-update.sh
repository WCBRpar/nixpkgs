#!/usr/bin/env bash
# odoo-hash-update.sh
# Atualiza hashes de pacotes Odoo agrupando por repositório.
# Obtém a lista de pacotes do pkgs/top-level/all-packages.nix,
# agrupa por owner/repo e calcula o hash uma vez por repositório.
#
# Uso: ./odoo-hash-update.sh [--dry-run] [--token TOKEN]

set -uo pipefail

NIXPKGS_DIR=$(cd "$(dirname "$0")/.." && pwd)
ALL_PACKAGES="$NIXPKGS_DIR/pkgs/top-level/all-packages.nix"
DRY_RUN=false

# Sem token hardcoded. Se quiser autenticação, exporte GITHUB_TOKEN no shell.
: "${GITHUB_TOKEN:=}"

usage() {
  cat <<EOF
Uso: $0 [--dry-run] [--help]
EOF
  exit 0
}

# Re-exec dentro de nix-shell (quoting correcto)
if [[ -z "${IN_NIX_SHELL:-}" ]]; then
  if ! command -v jq &>/dev/null || ! command -v nix-prefetch-github &>/dev/null; then
    export IN_NIX_SHELL=1
    exec nix-shell -p curl jq nix-prefetch-github --run 'bash "$0" "$@"' -- "$0" "$@"
  fi
fi

extrair_campo() {
  local arquivo=$1 campo=$2
  grep -E "^[[:space:]]*${campo}[[:space:]]*=[[:space:]]*\"([^\"]+)\"" "$arquivo" \
    | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

hash_atual() {
  grep -oP 'hash = "\K[^"]+' "$1" | head -1
}

# Lê pacotes
mapfile -t PACOTES < <(perl -ne '
  if (/^\s*odooAddons\s*=\s*with\s+pkgs\s*;\s*recurseIntoAttrs\s*\{/) { $inside=1; next; }
  if ($inside && /^\s*\};?\s*$/) { $inside=0; next; }
  if ($inside && /^\s*([a-zA-Z0-9_-]+)\s*=\s*callPackage\s+.*;$/) { print "$1\n"; }
' "$ALL_PACKAGES")

[[ ${#PACOTES[@]} -eq 0 ]] && { echo "❌ Nenhum pacote encontrado"; exit 1; }
echo "✅ ${#PACOTES[@]} pacotes encontrados."

# Agrupa por (owner, repo, version). Versões diferentes → hashes diferentes.
declare -A REPO_KEY   # chave: owner/repo/version → lista de ficheiros
for pkg in "${PACOTES[@]}"; do
  shard="${pkg:0:2}"
  f="$NIXPKGS_DIR/pkgs/by-name/$shard/$pkg/package.nix"
  [[ -f "$f" ]] || { echo "⚠  $pkg: ficheiro ausente"; continue; }

  owner=$(extrair_campo "$f" owner)
  repo=$(extrair_campo "$f" repo)
  version=$(extrair_campo "$f" version)
  [[ -z "$owner" || -z "$repo" || -z "$version" ]] && { echo "⚠  $pkg: campos em falta"; continue; }

  key="$owner/$repo/$version"
  REPO_KEY["$key"]+="$f;"
done

echo "📦 ${#REPO_KEY[@]} grupos (owner/repo/versão) distintos."

# Processa cada grupo
for key in "${!REPO_KEY[@]}"; do
  IFS='/' read -r owner repo version <<< "$key"
  echo ""
  echo "🔍 $owner/$repo @ $version"

  out=$(nix-prefetch-github "$owner" "$repo" --rev "$version" 2>/dev/null)
  hash=$(echo "$out" | jq -r '.hash // empty')
  rev=$(echo "$out" | jq -r '.rev  // empty')

  [[ -z "$hash" ]] && { echo "   ❌ Falha ao obter hash"; continue; }
  echo "   ✅ hash: $hash"
  [[ -n "$rev" ]] && echo "   📌 rev: $rev (use como version para pin estável)"

  IFS=';' read -ra FILES <<< "${REPO_KEY[$key]}"
  for f in "${FILES[@]}"; do
    [[ -z "$f" ]] && continue
    old=$(hash_atual "$f")

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "   [DRY] $f : $old → $hash"
      continue
    fi

    sed -i "s#hash = \"[^\"]*\"#hash = \"$hash\"#" "$f"

    new=$(hash_atual "$f")
    if [[ "$new" != "$hash" ]]; then
      echo "   ✗ $f : sed NÃO aplicou (old=$old new=$new)"
    elif [[ "$old" == "$hash" ]]; then
      echo "   = $f : já estava correcto"
    else
      echo "   ✓ $f : actualizado"
    fi
  done
done
