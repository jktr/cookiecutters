{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  let
    systems = nixpkgs.lib.platforms.unix;
    forAllSystems = fn: (nixpkgs.lib.genAttrs systems (system:
      fn (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
        ];
      })
    ));
  in {
    apps = forAllSystems (pkgs: rec {
      default = {{ cookiecutter.project_slug }};
      {{ cookiecutter.project_slug }} = {
        type = "app";
        program = "${pkgs.{{ cookiecutter.project_slug }}}/bin/{{ cookiecutter.project_slug }}";
      };
    });

    packages = forAllSystems (pkgs: rec {
      default = pkgs.{{ cookiecutter.project_slug }};
    });

    overlays = {
      default = final: prev: {
        {{ cookiecutter.project_slug }} = final.buildGoModule rec {
          pname = "{{ cookiecutter.project_slug }}";
          version = "0.0.1";
          src = ./.;
          vendorHash = null;
        };
      };
    };

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs
          =  [
            pkgs.go
            pkgs.gopls
          ]
          ++ pkgs.{{ cookiecutter.project_slug }}.buildInputs
          ++ pkgs.{{ cookiecutter.project_slug }}.propagatedBuildInputs;

        shellHook = ''
        '';
      };
    });
  };
}
