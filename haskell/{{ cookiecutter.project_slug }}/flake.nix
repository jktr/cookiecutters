{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  with nixpkgs.lib;
  let
    systems = platforms.unix;
    forAllSystems = genAttrs systems;
    getHaskellPackages = pkgs: pattern: pipe pkgs.haskell.packages [
      attrNames
      (filter (x: !isNull (strings.match pattern x)))
      (sort (x: y: x>y))
      (map (x: pkgs.haskell.packages.${x}))
      head
    ];
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; overlays = [
        self.overlays.default
      ]; };
      {{ cookiecutter.ghc }} = getHaskellPackages pkgs "{{ cookiecutter.ghc }}.";
    in rec {
      default = {{ cookiecutter.project_slug }};
      {{ cookiecutter.project_slug }} = {{ cookiecutter.ghc }}.{{ cookiecutter.project_slug }};
    });

    overlays = {
      default = final: prev: {
        haskell = prev.haskell // {
          packageOverrides = hfinal: hprev: prev.haskell.packageOverrides hfinal hprev // {
            {{ cookiecutter.project_slug }} = hfinal.callCabal2nix "{{ cookiecutter.project_slug }}" ./{{ cookiecutter.project_slug }} {};

            # https://gitlab.haskell.org/ghc/ghc/-/issues/22425
            ListLike = final.haskell.lib.dontCheck hprev.ListLike;
          };
        };
      };
    };

    devShells = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [
          self.overlays.default
        ]; };
        haskellPackages = getHaskellPackages pkgs "{{ cookiecutter.ghc }}.";
      in rec {
        default = haskellPackages.shellFor {
          packages = hpkgs: [
            hpkgs.{{ cookiecutter.project_slug }}
          ];
          nativeBuildInputs = [
            haskellPackages.haskell-language-server
            pkgs.cabal-install
            #pkgs.cabal-plan
            pkgs.hlint

            (pkgs.writeShellScriptBin "ghcid-wrapper" ''

              readonly target=''${1:-lib:{{ cookiecutter.project_slug }}}
              readonly executable=''${2:-lib:{{ cookiecutter.project_slug }}}

              if [ -n "$executable" ]; then
                readonly run_exe="cabal run \
                  --disable-optimisation \
                  --ghc-option -fdiagnostics-color=always \
                  $executable \
                  "
              else
                readonly run_exe=true
              fi

              ${pkgs.zsh}/bin/zsh -c 'print -P %F{yellow}Cleaning repository%f'
              cabal clean

              (
                ${pkgs.git}/bin/git ls-files test
                ${pkgs.git}/bin/git ls-files '*cabal'
                ${pkgs.git}/bin/git ls-files 'flake.*'
              )|\
              ${pkgs.entr}/bin/entr -r \
                ${pkgs.nix}/bin/nix develop -c \
                  ${pkgs.ghcid}/bin/ghcid \
                    --warnings \
                    "--command=cabal repl $target" \
                    "--test=:! \
                      cabal test \
                        --disable-optimisation \
                        --test-show-details=direct \
                        --ghc-option -fdiagnostics-color=always && \
                      $run_exe && \
                      ${pkgs.zsh}/bin/zsh -c 'print -P %F{green}Build and tests passed%f' \
                      "
            '')
          ];
        };
      }
    );
  };
}
