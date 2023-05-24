{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  with nixpkgs.lib;
  let
    systems = platforms.unix;
    forAllSystems = fn: (genAttrs systems (system:
      fn (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
        ];
      })
    ));
    getHaskellPackages = pkgs: pattern: pipe pkgs.haskell.packages [
      attrNames
      (filter (x: !isNull (strings.match pattern x)))
      (sort (x: y: x>y))
      (map (x: pkgs.haskell.packages.${x}))
      head
    ];
  in {
    packages = forAllSystems (pkgs: let
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
          };
        };
      };
    };

    devShells = forAllSystems (pkgs:
      let
        haskellPackages = getHaskellPackages pkgs "{{ cookiecutter.ghc }}.";
      in rec {
        default = haskellPackages.shellFor {
          packages = hpkgs: [
            hpkgs.{{ cookiecutter.project_slug }}
          ];
          nativeBuildInputs = [
            haskellPackages.haskell-language-server
            pkgs.cabal-install
            pkgs.hlint

            # in addition, for ghcid-wrapper
            pkgs.zsh
            pkgs.entr
            pkgs.ghcid
          ];
        };
      }
    );
  };
}
