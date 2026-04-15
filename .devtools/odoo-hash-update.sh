#!/usr/bin/env bash

# Script para atualizar hashes de pacotes Odoo addons usando nix-prefetch-github
# Obtém a lista de pacotes diretamente do pkgs/top-level/all-packages.nix
# Coloque este script no diretório ./devtools/ do seu nixpkgs e execute.

set -euo pipefail

# Diretório raiz do nixpkgs (um nível acima de onde o script está)
NIXPKGS_DIR=$(cd "$(dirname "$0")/.." && pwd)
echo "📂 Diretório nixpkgs: $NIXPKGS_DIR"

ALL_PACKAGES="$NIXPKGS_DIR/pkgs/top-level/all-packages.nix"

# Verifica se o arquivo all-packages.nix existe
if [ ! -f "$ALL_PACKAGES" ]; then
    echo "❌ Erro: Arquivo $ALL_PACKAGES não encontrado."
    exit 1
fi

echo "📄 Extraindo lista de pacotes de odooAddons em $ALL_PACKAGES ..."

# Extrai os nomes dos pacotes dentro de odooAddons = { ... }
# Esta expressão perl captura linhas do tipo:   nome-do-pacote = callPackage ...;
mapfile -t PACOTES < <(perl -ne '
    if (/^\s*odooAddons\s*=\s*with\s+pkgs\s*;\s*recurseIntoAttrs\s*\{/) {
        $inside = 1;
        next;
    }
    if ($inside && /^\s*\};?\s*$/) {
        $inside = 0;
        next;
    }
    if ($inside && /^\s*([a-zA-Z0-9_-]+)\s*=\s*callPackage\s+.*;$/) {
        print "$1\n";
    }
' "$ALL_PACKAGES")

if [ ${#PACOTES[@]} -eq 0 ]; then
    echo "❌ Nenhum pacote encontrado em odooAddons no $ALL_PACKAGES"
    exit 1
fi

echo "✅ Encontrados ${#PACOTES[@]} pacotes:"
printf '   %s\n' "${PACOTES[@]}"
echo ""

# Função para extrair um campo de um arquivo .nix (valor entre aspas)
extrair_campo() {
    local arquivo=$1
    local campo=$2
    grep -oP "$campo\s*=\s*\"\K[^\"]+" "$arquivo" | head -1
}

# Contadores
total=0
sucesso=0
falha=0
ignorados=0

# Processa cada pacote
for pkg in "${PACOTES[@]}"; do
    echo "🔍 Processando $pkg ..."

    # Determina o shard (primeiras duas letras do nome)
    shard="${pkg:0:2}"

    # Caminho do package.nix
    package_path="$NIXPKGS_DIR/pkgs/by-name/$shard/$pkg/package.nix"

    if [ ! -f "$package_path" ]; then
        echo "  ⚠️ Arquivo não encontrado: $package_path (ignorando)"
        ignorados=$((ignorados+1))
        continue
    fi

    # Extrai owner, repo e version
    owner=$(extrair_campo "$package_path" "owner")
    repo=$(extrair_campo "$package_path" "repo")
    version=$(extrair_campo "$package_path" "version")

    if [ -z "$owner" ] || [ -z "$repo" ] || [ -z "$version" ]; then
        echo "  ❌ Campos obrigatórios (owner, repo, version) não encontrados em $package_path"
        falha=$((falha+1))
        continue
    fi

    echo "  📦 $owner/$repo @ $version"

    # Obtém o hash usando nix-prefetch-github
    if command -v nix-prefetch-github &> /dev/null; then
        hash=$(nix-prefetch-github "$owner" "$repo" --rev "$version" 2>/dev/null | jq -r '.hash')
    else
        echo "  ⚠️ nix-prefetch-github não encontrado, tentando com nix-shell..."
        hash=$(nix-shell -p nix-prefetch-github jq --run "nix-prefetch-github '$owner' '$repo' --rev '$version' 2>/dev/null | jq -r '.hash'")
    fi

    if [ -z "$hash" ] || [ "$hash" = "null" ]; then
        echo "  ❌ Falha ao obter hash para $owner/$repo @ $version"
        falha=$((falha+1))
        continue
    fi

    # Limpa possíveis quebras de linha
    hash=$(echo "$hash" | tr -d '\n')
    echo "  ✅ Hash obtido: $hash"

    # Substitui o hash no arquivo (supõe linha do tipo hash = "alguma-coisa")
    sed -i "s|hash = \".*\"|hash = \"$hash\"|" "$package_path"

    if [ $? -eq 0 ]; then
        echo "  ✓ Hash atualizado em $package_path"
        sucesso=$((sucesso+1))
    else
        echo "  ✗ Falha ao atualizar hash em $package_path"
        falha=$((falha+1))
    fi

    total=$((total+1))
    echo ""
done

# Resumo final
echo "================ RESUMO ================"
echo "Total processado: $total"
echo "Sucesso: $sucesso"
echo "Falhas: $falha"
echo "Ignorados (arquivo não encontrado): $ignorados"
