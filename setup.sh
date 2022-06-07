#! /bin/bash

set -eux

sudo apt-get update -qq
sudo apt-get install --yes apt-transport-https curl lsb-release software-properties-common sudo wget

DISTRO="$(lsb_release --short --id)"
DISTRO="${DISTRO,,}" # Make lowercase: e.g. Debian -> debian, Ubuntu -> ubuntu
CODENAME="$(lsb_release --short --codename)"

BASEDIST="$DISTRO"
if [[ "$BASEDIST" = "neon" ]]; then
  BASEDIST="ubuntu"
fi

rm --recursive --force /tmp/setup-phanective

mkdir /tmp/setup-phanective
cd /tmp/setup-phanective

sudo apt-get remove --yes --ignore-missing \
  akregator \
  amarok \
  dragonplayer \
  fonts-droid \
  fonts-horai-umefont \
  fonts-takao-pgothic \
  jovie \
  juk \
  kaddressbook \
  kde-telepathy-contact-list \
  kde-telepathy-text-ui \
  kmag \
  kmail \
  kmousetool \
  kmouth \
  knotes \
  kolourpaint4 \
  kontact \
  konversation \
  kopete \
  korganizer \
  kwrite \
  krdc \
  ktorrent \
  openjdk-7-* \
  partitionmanager \
  xterm

if [[ "${DISTRO}" == "debian" ]]; then
  sudo apt-get remove --yes --ignore-missing \
    kde-full \
    kde-standard \
    kdeplasma-addons \
    plasma-scriptengine-superkaramba \
    plasma-widget-lancelot
fi

sudo apt-get autoremove --yes
sudo apt-get dist-upgrade --yes

# Add Node.js Repo
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Add VirtualBox Repo
echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

# Add Hashicorp Repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update -qq

# Install from deb files
curl --silent --show-error --output /tmp/setup-phanective/docker-desktop.deb  --location "https://desktop.docker.com/linux/main/amd64/docker-desktop-4.9.0-amd64.deb"
curl --silent --show-error --output /tmp/setup-phanective/dropbox.deb --location "https://www.dropbox.com/download?dl=packages/$BASEDIST/dropbox_2019.02.14_amd64.deb"
curl --silent --show-error --output /tmp/setup-phanective/vscode.deb  --location "https://go.microsoft.com/fwlink/?LinkID=760868"

# Ignore error that dependencies are not installed
set +eu
  sudo dpkg --install \
    /tmp/setup-phanective/docker-desktop.deb \
    /tmp/setup-phanective/dropbox.deb \
    /tmp/setup-phanective/vscode.deb
set -eux

sudo apt-get --fix-broken install --yes
sudo apt-get install --yes --no-install-recommends --ignore-missing \
  apt-transport-https \
  build-essential \
  clamav \
  curl \
  git \
  fcitx \
  fcitx-mozc \
  firefox \
  fonts-vlgothic \
  kde-config-fcitx \
  kolourpaint \
  nodejs \
  openssh-client \
  snapd \
  sudo \
  uvccapture guvcview \
  vagrant \
  virtualbox-6.1 \
  vlc \
  wget \
  whois \
  yakuake

if [[ "$BASEDIST" = "debian" ]]; then
  snap install firefox
fi

# Dropbox proprietary daemon installation
(cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -)
dropbox autostart y

# Allow Dropbox to watch more number of files
echo "fs.inotify.max_user_watches = 100000" | sudo tee /etc/sysctl.d/dropbox.conf

# Vagrant plugins
vagrant plugin install vagrant-vbguest

sudo npm update --global

#
# git config
#

# Don't convert line endings to CRLF
git config --global core.autocrlf false
# Don't commit file permission change
git config --global core.fileMode false

git config --global user.name "Jumpei Ogawa"
# git config --global user.email "phanect@example.com" # Do it manually

if [[ ! -f ~/.ssh/id_rsa ]]; then
  ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""
fi

rm --recursive --force /tmp/setup-phanective
