#!/usr/bin/env bash

{% if cookiecutter.nixpkgs %}
nix flake lock --override-input nixpkgs 'github:NixOS/nixpkgs/{{ cookiecutter.nixpkgs }}'
{% endif %}

# show flake setup (and generate flake.lock if we don't have a pinned nixpkgs version)
nix flake metadata

nix run nixpkgs#go mod init "{{ cookiecutter.module_path }}"

git init
git add -A
git commit -m 'initial commit'
