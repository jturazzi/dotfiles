#!/usr/bin/env bash
# Prépare un serveur de dev avec ces dotfiles : installe oh-my-zsh + plugins,
# puis symlink les fichiers de config suivis dans $HOME.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

# --- Étape 1 : dépendances ------------------------------------------------
log "Étape 1/6 : vérification des dépendances (git, curl, zsh)"
missing=()
for bin in git curl zsh; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done

if [[ ${#missing[@]} -gt 0 ]]; then
  command -v apt-get >/dev/null 2>&1 || {
    echo "Dépendances manquantes : ${missing[*]} (installe-les d'abord, apt-get introuvable)" >&2
    exit 1
  }
  log "Installation des dépendances manquantes : ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
fi

# --- Étape 2 : oh-my-zsh ---------------------------------------------------
log "Étape 2/6 : installation d'oh-my-zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installation d'oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "oh-my-zsh déjà installé, on passe"
fi

# --- Étape 3 : plugins & thème ---------------------------------------------
log "Étape 3/6 : installation des plugins et du thème"
clone_if_missing() {
  local repo="$1" dest="$2"
  if [[ ! -d "$dest" ]]; then
    log "Clonage de $(basename "$dest")"
    git clone --depth 1 "$repo" "$dest"
  else
    log "$(basename "$dest") déjà présent, on passe"
  fi
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"

# --- Étape 4 : symlink des dotfiles -----------------------------------------
log "Étape 4/6 : création des liens symboliques vers \$HOME"
# correspondance : fichier du repo -> chemin cible dans $HOME
declare -A LINKS=(
  [.zshrc]="$HOME/.zshrc"
  [.p10k.zsh]="$HOME/.p10k.zsh"
  [.aliases]="$HOME/.aliases"
  [.functions]="$HOME/.functions"
  [.gitconfig]="$HOME/.gitconfig"
  [selected_editor]="$HOME/.selected_editor"
)

for src in "${!LINKS[@]}"; do
  target="${LINKS[$src]}"
  source_path="$DOTFILES_DIR/$src"

  if [[ ! -e "$source_path" ]]; then
    log "Ignoré : $src n'existe pas dans le dépôt"
    continue
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source_path" ]]; then
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    log "Sauvegarde de $target existant -> $BACKUP_DIR/"
    mv "$target" "$BACKUP_DIR/"
  fi

  ln -s "$source_path" "$target"
  log "Lien créé : $target -> $source_path"
done

# --- Étape 5 : polices ------------------------------------------------------
log "Étape 5/6 : installation des polices MesloLGS NF (recommandées pour p10k)"
FONTS_DIR="$HOME/.local/share/fonts"
if [[ -d "$DOTFILES_DIR/fonts" ]]; then
  mkdir -p "$FONTS_DIR"
  cp -n "$DOTFILES_DIR"/fonts/*.ttf "$FONTS_DIR/"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONTS_DIR" >/dev/null
  log "Polices installées dans $FONTS_DIR"
else
  log "Dossier fonts/ absent, étape ignorée"
fi

# --- Étape 6 : signature des commits ----------------------------------------
log "Étape 6/6 : vérification de la clé de signature git"
SIGNING_KEY="$HOME/.ssh/id_ed25519"
if [[ -f "$SIGNING_KEY.pub" ]]; then
  log "Clé de signature trouvée ($SIGNING_KEY.pub)"
else
  log "Génération d'une clé ed25519 pour la signature des commits"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$SIGNING_KEY" -N "" -C "$(whoami)@$(hostname)"
  log "Clé générée : $SIGNING_KEY.pub"
  log "Ajoute-la sur GitHub : Settings > SSH and GPG keys > New SSH key (type 'Signing Key')"
  cat "$SIGNING_KEY.pub"
fi

log "Terminé. Les sauvegardes éventuelles sont dans $BACKUP_DIR"
log "Pense à définir zsh comme shell par défaut si besoin : chsh -s \$(command -v zsh)"
log "Pense à configurer ton terminal pour utiliser la police MesloLGS NF"
