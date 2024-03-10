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
        {{ cookiecutter.project_slug }} = final.{{ cookiecutter.python }}.pkgs.buildPythonApplication rec {
          pname = "{{ cookiecutter.project_slug }}";
          version = "0.0.1";
          format = "pyproject";
          src = ./.;
          buildInputs = with final.{{ cookiecutter.python }}.pkgs; [
            setuptools
          ];
          propagatedBuildInputs = with final.{{ cookiecutter.python }}.pkgs; [
            {%- for DEP in cookiecutter.dependencies.default %}
            {{ DEP }}
            {%- endfor %}
          ];
        };
      };
    };

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs
          =  [
            pkgs.{{ cookiecutter.python }}
            pkgs.nodePackages.pyright
          ]
          ++ pkgs.{{ cookiecutter.project_slug }}.buildInputs
          ++ pkgs.{{ cookiecutter.project_slug }}.propagatedBuildInputs;

        shellHook = ''
        '';
      };
    });
  };
}
