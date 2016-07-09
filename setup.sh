#! /bin/bash

set -eux

sudo apt-get update -qq
sudo apt-get install --yes apt-transport-https curl jq lsb-release software-properties-common sudo wget

PATH_PACKAGES_JSON="$(dirname "$BASH_SOURCE")/packages.json"

DISTRO="$(lsb_release --short --id)"
DISTRO="${DISTRO,,}" # Make lowercase: e.g. Debian -> debian, Ubuntu -> ubuntu
CODENAME="$(lsb_release --short --codename)"

PKGS_INSTALL="$(jq --raw-output '.install.all | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.all | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.$CODENAME | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$(jq --raw-output '.remove.all | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.all | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.$CODENAME | join(\" \")" < "$PATH_PACKAGES_JSON")"

rm -rf /tmp/setup-phanective

mkdir /tmp/setup-phanective
cd /tmp/setup-phanective

sudo apt-get remove --yes $PKGS_REMOVE

sudo apt-get autoremove -y
sudo apt-get dist-upgrade -y

if [ "$DISTRO" = "ubuntu" ]; then
  # Add universe and multiverse
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME universe multiverse"
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME-updates universe multiverse"
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME-security universe multiverse"

  # Add PPAs
  sudo apt-add-repository ppa:ansible/ansible
  sudo add-apt-repository ppa:webupd8team/brackets
elif [ "$DISTRO" = "debian" ]; then
  DEBIAN_MAIN_REPO="http://ftp.jaist.ac.jp/debian/" # JAIST
  # local DEBIAN_MAIN_REPO="http://httpredir.debian.org/debian/" # Redir

  sudo rm -f /etc/apt/sources.list
  sudo touch /etc/apt/sources.list

  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME main contrib non-free"
  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME-updates main contrib non-free"
  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME-backports main contrib non-free" # for openjdk-8-*
  sudo add-apt-repository "deb http://security.debian.org $CODENAME/updates main contrib non-free"
fi

# Add VirtualBox Repo
echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

# Add Docker Repo
echo "deb https://apt.dockerproject.org/repo $DISTRO-$CODENAME main" | sudo tee /etc/apt/sources.list.d/docker.list
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

sudo apt-get update -qq

# Install Dropbox
curl --silent --show-error --output /tmp/setup-phanective/dropbox.deb --location "https://www.dropbox.com/download?dl=packages/$DISTRO/dropbox_2015.10.28_amd64.deb"
set +eu; sudo dpkg --install /tmp/setup-phanective/dropbox.deb; set -eu # Occurs error that dependencies are not installed

sudo apt-get --fix-broken install --yes --no-install-recommends $PKGS_INSTALL

# Dropbox proprietary daemon installation
(cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -)
dropbox autostart y
dropbox start --install

#
# Node.js Environment Setup
#

# Get latest version of NVM
NVM_LATEST=$(curl --silent --show-error https://api.github.com/repos/creationix/nvm/releases/latest | jq --raw-output .name)

touch ~/.bashrc
curl --silent --show-error "https://raw.githubusercontent.com/creationix/nvm/$NVM_LATEST/install.sh" | bash
source ~/.profile
nvm install 4
nvm use 4
nvm alias default 4
npm install --global npm
npm install -g bower eslint geddy gulp

# Python Environment Setup
curl --silent --show-error --location https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Python build dependencies
sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev make

if ! grep --fixed-strings --line-regexp "# PyEnv" ~/.bashrc; then
cat << _EOF_ >> ~/.bashrc

# PyEnv Setup
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
_EOF_
fi

PYTON_LATEST="$(pyenv install --list | tr --delete " " | grep --extended-regexp ^[0-9\.]+$ | tac | grep --max-count=1 .)"
pyenv install "$PYTON_LATEST"
pyenv global "$PYTON_LATEST"

if [[ "$DISTRO" = "debian" ]]; then
  pip install ansible
fi

#
# git config
#

# Don't commit file permission change
git config --global core.fileMode false

#
# Aliases
#
if ! grep --fixed-strings --line-regexp "# colordiff" ~/.bashrc; then
cat << _EOF_ >> ~/.bashrc

# colordiff
if [[ -x "$(which colordiff)" ]]; then
alias diff="colordiff -u"
export LESS='--RAW-CONTROL-CHARS'
fi
_EOF_
fi

if [[ ! -f ~/.ssh/id_rsa ]]; then
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ""
fi

rm -rf /tmp/setup-phanective

source ~/.bashrc
