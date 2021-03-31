#!/bin/sh

set -u # error on use of undefined variable
set -e # exit on error

install_path="$HOME/.local/bin"

if command -v stack 1> /dev/null 2>&1 ; then
  echo "found stack"
else
  echo "Haskell stack not found."
  echo "Installing Haskell stack to."
  curl -sSL https://get.haskellstack.org/ | sh
  if command -v stack 1> /dev/null 2>&1 ; then
    echo "Haskell stack installation successful."
  else
    echo "Haskell stack installation unsuccessful."
    exit 1
  fi
fi

if [ -x "$install_path/fpm" ]; then
  echo "Overwriting existing fpm installation in $install_path"
fi

cd bootstrap
stack install

if [ -x "$install_path/fpm" ]; then
  echo "fpm installed successfully to $install_path"
else
  echo "fpm installation unsuccessful: fpm not found in $install_path"
fi