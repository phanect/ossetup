#! /bin/bash

set -eu

sudo apt-get update
sudo apt-get install --yes apt-transport-https curl jq lsb-release software-properties-common sudo wget

PATH_PACKAGES_JSON="$(dirname "$BASH_SOURCE")/packages.json"

DISTRO="$(lsb_release --short --id)"
DISTRO="${DISTRO,,}" # Make lowercase: e.g. Debian -> debian, Ubuntu -> ubuntu
CODENAME="$(lsb_release --short --codename)"

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
elif [ "$DISTRO" = "debian" ]; then
  DEBIAN_MAIN_REPO="http://ftp.jaist.ac.jp/debian/" # JAIST
  # local DEBIAN_MAIN_REPO="http://httpredir.debian.org/debian/" # Redir

  sudo rm -f /etc/apt/sources.list
  sudo touch /etc/apt/sources.list

  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME main contrib non-free"
  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME-updates main contrib non-free"
  sudo add-apt-repository "deb http://security.debian.org $CODENAME/updates main contrib non-free"
fi

# Add VirtualBox Repo
sudo add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib"
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# Add Dropbox Repo
sudo add-apt-repository "deb http://linux.dropbox.com/ubuntu $CODENAME main"
apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E

# Add Docker Repo
sudo add-apt-repository "deb https://apt.dockerproject.org/repo ubuntu-$CODENAME main"
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Add Ansible Repo
sudo apt-add-repository ppa:ansible/ansible

sudo apt-get update
sudo apt-get install -y curl flashplugin-installer fonts-vlgothic jq kolourpaint4 muon vlc whois yakuake \
dropbox python-gpgme \
fcitx fcitx-mozc kde-config-fcitx \
colordiff default-jre-headless g++ git kdesdk-dolphin-plugins virtualbox-5.0 \
docker-engine ansible python-libcloud

# Brackets
if [[ "$CODENAME" == "vivid" ]]; then
  # TODO Link no longer work, replace it to one provided in Ubuntu 14.04 LTS official repo
  wget -O libgcrypt11.deb http://mirrors.kernel.org/ubuntu/pool/main/libg/libgcrypt11/libgcrypt11_1.5.3-2ubuntu4.2_amd64.deb
  sudo dpkg --install ./libgcrypt11.deb
fi

wget -O brackets.deb https://github.com/adobe/brackets/releases/download/release-1.5/Brackets.Release.1.5.64-bit.deb
sudo dpkg --install ./brackets.deb
sudo apt-get install --fix-broken

#
# Node.js Environment Setup
#

# Get latest version of NVM
NVM_LATEST=$(curl https://api.github.com/repos/creationix/nvm/releases/latest | jq --raw-output .name)

touch ~/.bashrc
curl "https://raw.githubusercontent.com/creationix/nvm/$NVM_LATEST/install.sh" | bash
source ~/.profile
nvm install stable
nvm use stable
nvm alias default stable
npm install -g bower eslint geddy gulp

# Python Environment Setup
curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Python build dependencies
sudo apt-get install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev

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
pip install ansible

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

dropbox autostart y
dropbox start -i
