# dotfiles

Follow the steps below when configuring new private MAC:

## 1. Create SSH Connection To GH

In your terminal:

```
ssh-keygen -o -t rsa -C "email@example.com"
```

Follow the steps to create SSH certificate, then copy the public key into the
corresponfing field when creating SSH key in GH account.

Open `~/.ssh/config` and add the following fields:

```
PubkeyAuthentication yes
PubkeyAcceptedKeyTypes=+ssh-rsa
ServerAliveCountMax 0
ServerAliveInterval 900
```

## 2. Clone Repository To Home Directory

In your terminal:

```
git clone git@github.com:bensaadaCanine/dotfiles.git ~/.dotfiles
```

## 3. Effuse

```
sudo gem install effuse
cd ~/.dotfiles
effuse
```

## 4. HomeBrew

In your terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/opt/homebrew/bin:${PATH}"
source ~/.zprofile
brew bundle --file ~/.dotfiles/Brewfile
```

## 5. Another Installments

oh-my-zsh:

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

tmux:

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source ~/.tmux.conf
```
