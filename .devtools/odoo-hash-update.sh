#!/usr/bin/env bash
# odoo-hash-update.sh
# Atualiza hashes de pacotes Odoo agrupando por repositório.
# Obtém a lista de pacotes do pkgs/top-level/all-packages.nix,
# agrupa por owner/repo e calcula o hash uma vez por repositório.
#
# Uso: ./odoo-hash-update.sh [--dry-run] [--token TOKEN]

set -uo pipefail

# ================= CONFIGURAÇÃO =================
NIXPKGS_DIR=$(cd "$(dirname "$0")/.." && pwd)
ALL_PACKAGES="$NIXPKGS_DIR/pkgs/top-level/all-packages.nix"
DRY_RUN=false

# Token GitHub (opcional, usado apenas para verificação de branch, mas não obrigatório)
DEFAULT_GITHUB_TOKEN="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"
GITHUB_TOKEN="${GITHUB_TOKEN:-$DEFAULT_GITHUB_TOKEN}"

# ================= FUNÇÕES =================
usage() {
    cat <<EOF
Uso: $0 [--dry-run] [--token TOKEN]

Opções:
  --dry-run           Apenas simula, não modifica arquivos.
  --token TOKEN       Token do GitHub (opcional).
  --help              Exibe esta ajuda.

A variável de ambiente GITHUB_TOKEN também pode ser usada.
EOF
    exit 0
}

# Executa dentro do nix-shell se faltar dependências
if [[ -z "${IN_NIX_SHELL:-}" ]]; then
    if ! command -v curl &>/dev/null || ! command -v jq &>/dev/null || ! command -v nix-prefetch-github &>/dev/null; then
        echo "🔧 Dependências faltando. Executando dentro de nix-shell..."
        export IN_NIX_SHELL=1
        exec nix-shell -p curl jq nix-prefetch-github --run "bash $0 $*"
    fi
fi

# Detecta token automaticamente (apenas para consistência)
detectar_token() {
    [[ -n "$GITHUB_TOKEN" ]] && return
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        GITHUB_TOKEN=$(gh auth token 2>/dev/null)
        [[ -n "$GITHUB_TOKEN" ]] && echo "🔑 Token obtido do 'gh' CLI" && return
    fi
    local remote_url=$(git -C "$NIXPKGS_DIR" config --get remote.origin.url 2>/dev/null)
    if [[ "$remote_url" == https://* ]]; then
        local cred_data=$(echo "url=$remote_url" | git credential fill 2>/dev/null)
        local token=$(echo "$cred_data" | sed -n 's/^password=//p')
        if [[ -n "$token" ]]; then
            GITHUB_TOKEN="$token"
            echo "🔑 Token obtido do git credential"
            return
        fi
    fi
    echo "⚠️  Nenhum token encontrado. Continuando sem autenticação (pode ser mais lento)."
}

# Extrai campo de package.nix (owner, repo, version, subdir)
extrair_campo() {
    local arquivo=$1 campo=$2
    grep -E "^[[:space:]]*${campo}[[:space:]]*=[[:space:]]*\"([^\"]+)\"" "$arquivo" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
}

# ================= LEITURA DOS PACOTES =================
carregar_pacotes() {
    if [[ ! -f "$ALL_PACKAGES" ]]; then
        echo "❌ Arquivo $ALL_PACKAGES não encontrado."
        exit 1
    fi

    echo "📄 Extraindo lista de addons Odoo de $ALL_PACKAGES ..."
    mapfile -t PACOTES < <(perl -ne '
if (/^\s*odooAddons\s*=\s*with\s+pkgs\s*;\s*recurseIntoAttrs\s*\{/) { $inside=1; next; }
if ($inside && /^\s*\};?\s*$/) { $inside=0; next; }
if ($inside && /^\s*([a-zA-Z0-9_-]+)\s*=\s*callPackage\s+.*;$/) { print "$1\n"; }
' "$ALL_PACKAGES")

    if [[ ${#PACOTES[@]} -eq 0 ]]; then
        echo "❌ Nenhum pacote encontrado em odooAddons."
        exit 1
    fi
    echo "✅ Encontrados ${#PACOTES[@]} pacotes."
}

# ================= AGRUPAMENTO POR REPOSITÓRIO =================
montar_repositorios() {
    declare -gA REPO_PACKAGES
    declare -gA REPO_VERSION
    local pkg_failures=0

    for pkg in "${PACOTES[@]}"; do
        shard="${pkg:0:2}"
        pkg_path="$NIXPKGS_DIR/pkgs/by-name/$shard/$pkg/package.nix"
        if [[ ! -f "$pkg_path" ]]; then
            echo "⚠  $pkg: arquivo não encontrado em $pkg_path (ignorado)"
            ((pkg_failures++))
            continue
        fi

        owner=$(extrair_campo "$pkg_path" "owner")
        repo=$(extrair_campo "$pkg_path" "repo")
        version=$(extrair_campo "$pkg_path" "version")
        # subdir não é necessário para hash, mas vamos extrair para diagnóstico
        subdir=$(extrair_campo "$pkg_path" "subdir")

        if [[ -z "$owner" || -z "$repo" || -z "$version" ]]; then
            echo "⚠  $pkg: campos obrigatórios (owner, repo, version) faltando - ignorado"
            ((pkg_failures++))
            continue
        fi

        repo_key="$owner/$repo"
        REPO_PACKAGES["$repo_key"]+="${pkg_path}|${subdir:-};"
        # Armazena a versão (assumimos que todos os pacotes do mesmo repo usam a mesma versão)
        REPO_VERSION["$repo_key"]="$version"
    done

    if [[ ${#REPO_PACKAGES[@]} -eq 0 ]]; then
        echo "❌ Nenhum pacote válido encontrado."
        exit 0
    fi
    echo "📦 Agrupados em ${#REPO_PACKAGES[@]} repositórios."
    [[ $pkg_failures -gt 0 ]] && echo "⚠️  $pkg_failures pacotes ignorados (problemas nos package.nix)"
}

# ================= PROCESSAMENTO (OBTER HASH E ATUALIZAR) =================
processar_repositorios() {
    local total=${#REPO_PACKAGES[@]}
    local processed=0
    local sucesso=0
    local falha=0
    local ignorados=0

    for repo_key in "${!REPO_PACKAGES[@]}"; do
        [[ -z "${REPO_PACKAGES[$repo_key]}" ]] && continue
        processed=$((processed + 1))
        echo ""
        echo "🔍 [$processed/$total] Repositório: $repo_key"

        IFS='/' read -r owner repo <<< "$repo_key"
        version="${REPO_VERSION[$repo_key]}"
        echo "   📦 $owner/$repo @ $version"

        # Obtém o hash usando nix-prefetch-github
        local hash
        if command -v nix-prefetch-github &>/dev/null; then
            hash=$(nix-prefetch-github "$owner" "$repo" --rev "$version" 2>/dev/null | jq -r '.hash')
        else
            echo "  ⚠ nix-prefetch-github não encontrado, tentando com nix-shell..."
            hash=$(nix-shell -p nix-prefetch-github jq --run "nix-prefetch-github '$owner' '$repo' --rev '$version' 2>/dev/null | jq -r '.hash'")
        fi

        if [[ -z "$hash" || "$hash" == "null" ]]; then
            echo "   ❌ Falha ao obter hash para $owner/$repo @ $version"
            ((falha++))
            continue
        fi

        hash=$(echo "$hash" | tr -d '\n')
        echo "   ✅ Hash obtido: $hash"

        # Atualiza todos os package.nix deste repositório
        IFS=';' read -ra ENTRIES <<< "${REPO_PACKAGES[$repo_key]}"
        local updated_count=0
        for entry in "${ENTRIES[@]}"; do
            [[ -z "$entry" ]] && continue
            pkg_path="${entry%|*}"
            subdir="${entry#*|}"
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "    [DRY RUN] Atualizaria $pkg_path (subdir=$subdir) com hash $hash"
            else
                sed -i "s|hash = \".*\"|hash = \"$hash\"|" "$pkg_path"
                if [[ $? -eq 0 ]]; then
                    echo "    ✓ $pkg_path atualizado"
                    ((updated_count++))
                else
                    echo "    ✗ Falha ao atualizar $pkg_path"
                fi
            fi
        done

        if [[ "$DRY_RUN" == "false" ]]; then
            echo "   ✓ $updated_count pacotes atualizados para este repositório."
        fi
        ((sucesso++))
    done

    echo ""
    echo "================ RESUMO ================"
    echo "Repositórios processados: $processed"
    echo "Sucesso: $sucesso"
    echo "Falhas (hash não obtido): $falha"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Modo DRY RUN – nenhum arquivo foi modificado."
    fi
}

# ================= MAIN =================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --token) GITHUB_TOKEN="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Opção desconhecida: $1"; usage ;;
    esac
done

detectar_token

echo "🚀 Atualizando hashes dos addons Odoo (agrupados por repositório)"
if [[ -n "$GITHUB_TOKEN" ]]; then
    echo "🔑 Usando token GitHub (opcional, não usado para hash, mas disponível)"
else
    echo "⚠️  Nenhum token. Prosseguindo sem autenticação."
fi
echo "   Dry-run: $DRY_RUN"
echo ""

carregar_pacotes
montar_repositorios
processar_repositorios
