#! /bin/bash

set -eux

DEBIAN_FRONTEND=noninteractive

sudo apt-get update -qq
sudo apt-get install --yes apt-transport-https curl jq lsb-release software-properties-common sudo wget

PATH_PACKAGES_JSON="$(dirname "$BASH_SOURCE")/packages.json"

DISTRO="$(lsb_release --short --id)"
DISTRO="${DISTRO,,}" # Make lowercase: e.g. Debian -> debian, Ubuntu -> ubuntu
CODENAME="$(lsb_release --short --codename)"

BASEDIST="$DISTRO"
if [[ "$BASEDIST" = "neon" ]]; then
  BASEDIST="ubuntu"
fi

PKGS_INSTALL="$(jq --raw-output '.install.all | arrays | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.all | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.$CODENAME | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$(jq --raw-output '.remove.all | arrays | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.all | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.$CODENAME | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"

rm --recursive --force /tmp/setup-phanective

mkdir /tmp/setup-phanective
cd /tmp/setup-phanective

sudo apt-get remove --yes --ignore-missing $PKGS_REMOVE

sudo apt-get autoremove --yes
sudo apt-get dist-upgrade --yes

if [[ "$BASEDIST" = "ubuntu" ]]; then
  # Add universe and multiverse
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME main restricted universe multiverse"
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME-updates main restricted universe multiverse"
  sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu/ $CODENAME-security main restricted universe multiverse"
elif [[ "$BASEDIST" = "debian" ]]; then
  DEBIAN_MAIN_REPO="http://ftp.jaist.ac.jp/debian/" # JAIST
  # local DEBIAN_MAIN_REPO="http://httpredir.debian.org/debian/" # Redir

  sudo rm --force /etc/apt/sources.list
  sudo touch /etc/apt/sources.list

  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME main contrib non-free"
  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME-updates main contrib non-free"
  sudo add-apt-repository "deb $DEBIAN_MAIN_REPO $CODENAME-backports main contrib non-free" # for openjdk-8-*
  sudo add-apt-repository "deb http://security.debian.org $CODENAME/updates main contrib non-free"
fi

# Add Node.js Repo
curl --sSL https://deb.nodesource.com/setup_12.x | sudo --preserve-env bash -

# Add yarn Repo
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add VirtualBox Repo
echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

# Add Docker Repo
echo "deb [arch=amd64] https://download.docker.com/linux/$BASEDIST $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list
curl -fsSL "https://download.docker.com/linux/$BASEDIST/gpg" | sudo apt-key add -

sudo apt-get update -qq

# Install from deb files
curl --silent --show-error --output /tmp/setup-phanective/atom.deb --location "https://atom.io/download/deb"
curl --silent --show-error --output /tmp/setup-phanective/dropbox.deb --location "https://www.dropbox.com/download?dl=packages/$BASEDIST/dropbox_2019.02.14_amd64.deb"
curl --silent --show-error --output /tmp/setup-phanective/vagrant.deb --location "https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb"

# Ignore error that dependencies are not installed
set +eu
  sudo dpkg --install \
    /tmp/setup-phanective/atom.deb \
    /tmp/setup-phanective/dropbox.deb \
    /tmp/setup-phanective/vagrant.deb
set -eux

sudo apt-get --fix-broken install --yes
sudo apt-get install --yes --no-install-recommends --ignore-missing $PKGS_INSTALL

# Snap
if [[ "$BASEDIST" = "debian" ]]; then
  snap install firefox
fi

# Dropbox proprietary daemon installation
(cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -)
dropbox autostart y

#
# Atom plugins
#
apm install \
  atom-typescript \
  auto-indent \
  autoclose-html \
  editorconfig \
  highlight-selected \
  indent-toggle-on-paste \
  incremental-search \
  language-babel \
  language-diff \
  language-docker \
  language-ejs \
  language-gitignore \
  language-htaccess \
  language-json5 \
  language-vue \
  linter \
  linter-eslint \
  linter-htmllint \
  linter-js-yaml \
  linter-jsonlint \
  linter-php \
  linter-shellcheck

# Disable unused build-in packages
# This doesn't work in most cases since apm disable requires ~/.atom/config.cson
# which is generated on the first run of Atom.
if [[ -f ~/.atom/config.cson ]]; then
  apm disable \
    atom-dark-syntax \
    atom-dark-ui \
    atom-light-syntax \
    atom-light-ui \
    base16-tomorrow-dark-theme \
    base16-tomorrow-light-theme \
    one-dark-ui \
    one-dark-syntax \
    solarized-dark-syntax \
    solarized-light-syntax \
    \
    styleguide \
    \
    language-c \
    language-clojure \
    language-coffee-script \
    language-csharp \
    language-java \
    language-objective-c \
    language-perl \
    language-property-list
fi

# Vagrant plugins
vagrant plugin install vagrant-vbguest

sudo npm update --global

#
# git config
#

# Don't commit file permission change
git config --global core.fileMode false
# Allow `git push`
git config --global push.default simple

#
# Allow non-root user to run Docker
#
sudo usermod --append --groups docker "$(whoami)"

if [[ ! -f ~/.ssh/id_rsa ]]; then
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ""
fi

rm --recursive --force /tmp/setup-phanective
