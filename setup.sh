#! /bin/bash

set -eux

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
curl -sSL https://deb.nodesource.com/setup_12.x | sudo --preserve-env bash -

# Add yarn Repo
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add VirtualBox Repo
echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

sudo apt-get update -qq

# Install from deb files
curl --silent --show-error --output /tmp/setup-phanective/dropbox.deb --location "https://www.dropbox.com/download?dl=packages/$BASEDIST/dropbox_2019.02.14_amd64.deb"
curl --silent --show-error --output /tmp/setup-phanective/vagrant.deb --location "https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb"

# Ignore error that dependencies are not installed
set +eu
  sudo dpkg --install \
    /tmp/setup-phanective/dropbox.deb \
    /tmp/setup-phanective/vagrant.deb
set -eux

sudo apt-get --fix-broken install --yes
sudo apt-get install --yes --no-install-recommends --ignore-missing \
  apt-transport-https \
  curl \
  dropbox \
  python-gpg \
  g++ \
  git \
  fcitx \
  fcitx-mozc \
  firefox \
  fonts-vlgothic \
  kde-config-fcitx \
  kdesdk-dolphin-plugins \
  jq \
  kolourpaint4 \
  make \
  nodejs \
  ntp \
  ntpdate \
  openjdk-8-jdk \
  openssh-client \
  plasma-widget-folderview \
  sudo \
  virtualbox-6.1 \
  vlc \
  wget \
  whois \
  yakuake \
  yarn

if [[ "${DISTRO}" == "debian" ]]; then
  sudo apt-get install --yes --no-install-recommends --ignore-missing \
    apper \
    snapd
fi

# Snap
sudo snap install circleci docker
sudo snap install atom --classic

sudo snap connect circleci:docker docker

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

# Don't convert line endings to CRLF
git config --global core.autocrlf false
# Don't commit file permission change
git config --global core.fileMode false
# Allow `git push`
git config --global push.default simple

if [[ ! -f ~/.ssh/id_rsa ]]; then
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ""
fi

rm --recursive --force /tmp/setup-phanective
