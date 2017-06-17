#!/bin/bash

OPAM_DEPEND="menhir jbuilder"

sh -e /etc/init.d/xvfb start

export ppa=avsm/ocaml42+opam12

sudo add-apt-repository -y ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam

export OPAMYES=1
opam init

eval `opam config env`
opam install ${OPAM_DEPEND}

make
make install
make tests
make examples
make clean
make uninstall
glxinfo
