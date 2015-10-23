#! /bin/bash

set -eu

rm -rf /tmp/setup-phanective

mkdir /tmp/setup-phanective
cd /tmp/setup-phanective

sudo apt-get remove -y akregator amarok dragonplayer kaddressbook \
kde-telepathy-contact-list kde-telepathy-legacy-presence-applet \
kde-telepathy-text-ui kmail kontact konversation korganizer krdc ktorrent \
fonts-droid fonts-horai-umefont fonts-takao-pgothic \
openjdk-7-jre openjdk-7-jre-headless partitionmanager

sudo apt-get update
sudo apt-get autoremove -y
sudo apt-get dist-upgrade -y

# Add VirtualBox Repo
sudo add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release --short --codename) contrib"
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# Add Dropbox Repo
sudo add-apt-repository "deb http://linux.dropbox.com/ubuntu $(lsb_release --short --codename) main"
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E

# Add Docker Repo
sudo add-apt-repository "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release --short --codename) main"
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Add Ansible Repo
sudo apt-add-repository ppa:ansible/ansible

sudo apt-get update
sudo apt-get install -y curl flashplugin-installer kolourpaint4 muon vlc whois yakuake \
dropbox python-gpgme \
fcitx fcitx-mozc kde-config-fcitx \
colordiff git kdesdk-dolphin-plugins virtualbox-5.0 \
docker-engine ansible python-libcloud

# Brackets
if [[ "$(lsb_release --short --codename)" == "vivid" ]]; then
  # TODO Link no longer work, replace it to one provided in Ubuntu 14.04 LTS official repo
  wget -O libgcrypt11.deb http://mirrors.kernel.org/ubuntu/pool/main/libg/libgcrypt11/libgcrypt11_1.5.3-2ubuntu4.2_amd64.deb
  sudo dpkg --install ./libgcrypt11.deb
fi

wget -O brackets.deb https://github.com/adobe/brackets/releases/download/release-1.4/Brackets.Release.1.4.64-bit.deb
sudo dpkg --install ./brackets.deb
sudo apt-get install --fix-broken

curl -o vlgothic.zip --location --remote-name "http://osdn.jp/frs/redir.php?m=iij&f=%2Fvlgothic%2F62375%2FVLGothic-20141206.zip"
unzip vlgothic.zip

mv ./VLGothic/VL-PGothic-Regular.ttf ~/Desktop
mv ./VLGothic/VL-Gothic-Regular.ttf ~/Desktop

#
# Node.js Environment Setup
#
touch ~/.bashrc
curl https://raw.githubusercontent.com/creationix/nvm/v0.24.1/install.sh | bash
source ~/.profile
nvm install stable
nvm use stable
nvm alias default stable
npm install -g bower eslint geddy gulp

# Python Environment Setup
curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

if ! grep --fixed-strings --line-regexp "# PyEnv" ~/.bashrc; then
cat << _EOF_ >> ~/.bashrc

# PyEnv Setup
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
_EOF_
fi

#
# git config
#

# Don't commit file permission change
git config core.fileMode false

#
# Aliases
#
if ! grep --fixed-strings --line-regexp "# colordiff" ~/.bashrc; then
cat << _EOF_ >> ~/.bashrc

# colordiff
if [[ -x `which colordiff` ]]; then
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
