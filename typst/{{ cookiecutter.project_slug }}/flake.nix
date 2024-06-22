{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  let
    systems = nixpkgs.lib.platforms.unix;
    forAllSystems = fn: (nixpkgs.lib.genAttrs systems (system:
      fn (import nixpkgs { inherit system; })
    ));
  in {
    packages = forAllSystems (pkgs: rec {
      default = {{ cookiecutter.project_slug }};
      {{ cookiecutter.project_slug }} = pkgs.runCommand "{{ cookiecutter.project_slug }}.pdf" {} ''
        mkdir $out
        ${pkgs.typst}/bin/typst compile ${./main.typ} $out/main.pdf
      '';
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs =  [
          pkgs.typst
          pkgs.typst-lsp
        ];
      };
    });
  };
}
