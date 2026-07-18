# dotfiles

Mes fichiers de configuration pour zsh + oh-my-zsh + powerlevel10k.

## Contenu

| Fichier           | Rôle                                                        |
|-------------------|-------------------------------------------------------------|
| `.zshrc`          | Config zsh (oh-my-zsh, thème, plugins)                      |
| `.p10k.zsh`       | Config du thème Powerlevel10k                               |
| `.aliases`        | Alias de commandes                                          |
| `.functions`      | Fonctions shell (extract, cheat, mkdircd, update-terminal…) |
| `.gitconfig`      | Config git (signature des commits en SSH)                   |
| `selected_editor` | Éditeur par défaut (utilisé par `select-editor`)            |

## Installation

```bash
git clone git@github.com:jturazzi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Le script :

1. vérifie les dépendances (`git`, `curl`, `zsh`) et installe automatiquement celles qui manquent via `apt-get` ;
2. installe oh-my-zsh si absent ;
3. installe les plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) et le thème `powerlevel10k` ;
4. crée des liens symboliques vers `$HOME` pour chaque fichier suivi (les fichiers existants sont sauvegardés dans `~/.dotfiles_backup/`) ;
5. génère une clé de signature git ed25519 (`~/.ssh/id_ed25519`) si elle n'existe pas encore, et affiche la clé publique à ajouter sur GitHub (Settings > SSH and GPG keys > New SSH key, type "Signing Key").

Pense ensuite à définir zsh comme shell par défaut si besoin :

```bash
chsh -s $(command -v zsh)
```

## Mise à jour

Une fois installé, la fonction `update-terminal` (dans `.functions`) fait un `git pull` du dépôt et recharge le shell.

## Licence

[MIT](LICENSE)
