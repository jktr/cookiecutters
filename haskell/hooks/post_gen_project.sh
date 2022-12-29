#!/usr/bin/env bash

# generate flake.lock
nix flake metadata

{% if cookiecutter.nixpkgs %}
nix flake lock --override-input nixpkgs 'github:NixOS/nixpkgs/{{ cookiecutter.nixpkgs }}'
{% endif %}

git init
git add -A
git commit -m 'inital commit'
