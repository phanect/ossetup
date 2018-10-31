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

PKGS_INSTALL="$(jq --raw-output '.install.all | arrays | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.all | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_INSTALL="$PKGS_INSTALL $(jq --raw-output ".install.$DISTRO.$CODENAME | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$(jq --raw-output '.remove.all | arrays | join(" ")' < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.all | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"
PKGS_REMOVE="$PKGS_REMOVE $(jq --raw-output ".remove.$DISTRO.$CODENAME | arrays | join(\" \")" < "$PATH_PACKAGES_JSON")"

rm --recursive --force /tmp/setup-phanective

mkdir /tmp/setup-phanective
cd /tmp/setup-phanective

sudo apt-get remove --yes $PKGS_REMOVE

sudo apt-get autoremove --yes
sudo apt-get dist-upgrade --yes

# Add Node.js Repo
curl --silent --location https://deb.nodesource.com/setup_10.x | sudo --preserve-env bash -

# Add yarn Repo
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add VirtualBox Repo
echo "deb http://download.virtualbox.org/virtualbox/debian $CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

sudo apt-get update -qq

# Install from deb files
curl --silent --show-error --output /tmp/setup-phanective/dropbox.deb --location "https://www.dropbox.com/download?dl=packages/$BASEDIST/dropbox_2015.10.28_amd64.deb"

# Ignore error that dependencies are not installed
set +eu
  sudo dpkg --install /tmp/setup-phanective/dropbox.deb
set -eux

sudo apt-get --fix-broken install --yes
sudo apt-get install --yes --no-install-recommends $PKGS_INSTALL

# Snap
sudo systemctl start snapd.service # If snapd is not running, start it

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
apm install atom-jinja2 \
  atom-typescript \
  auto-indent \
  editorconfig \
  highlight-selected \
  indent-toggle-on-paste \
  incremental-search \
  language-diff \
  language-docker \
  language-htaccess \
  language-json5 \
  language-vue \
  linter \
  linter-eslint \
  linter-htmllint \
  linter-js-yaml \
  linter-jsonlint \
  linter-pep8 \
  linter-php \
  linter-phpcs \
  linter-shellcheck

# Vagrant plugins
vagrant plugin install vagrant-vbguest

# NPMs
npm update --global

# Python Environment Setup
curl --silent --show-error --location https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Python build dependencies
sudo apt-get install --yes libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev make

if ! grep --fixed-strings --line-regexp "# PyEnv" ~/.bashrc; then
cat << _EOF_ >> ~/.bashrc

# PyEnv Setup
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
_EOF_
fi

export PATH="$HOME/.pyenv/bin:$PATH"

set +eu
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

PYTON_LATEST="$(pyenv install --list | tr --delete " " | grep --extended-regexp ^[0-9\.]+$ | tac | grep --max-count=1 .)"
pyenv install "$PYTON_LATEST"
pyenv global "$PYTON_LATEST"
set -eux

if [[ "$BASEDIST" = "debian" ]]; then
  pip install ansible
fi

#
# git config
#

# Don't commit file permission change
git config --global core.fileMode false
# Allow `git push`
git config --global push.default simple

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

rm --recursive --force /tmp/setup-phanective
