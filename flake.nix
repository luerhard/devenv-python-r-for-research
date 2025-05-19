{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs-python.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-trusted-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import .nix/r-overlay.nix)
          ]
        };

        kernelsDir = ".devenv/.jupyter/kernels";

        defaultSystemDeps = [
          # always system deps
          pkgs.gcc
          # weird build deps for rpy2
          pkgs.bzip2
          pkgs.icu
          pkgs.libdeflate
          pkgs.xz
          pkgs.zlib # # rpy2 deps end
        ] ++ pkgs.lib.lists.optionals pkgs.stdenv.isLinux [
          pkgs.glibcLocales
        ];

        defaultRPackages = with pkgs.rPackages; [
          box
          reticulate
          svglite
          IRkernel
          jsonlite
          languageserver
          lintr
        ];

      in
      {
        packages.devenv-up = self.devShells.${system}.default.config.procfileScript;
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            (
              { pkgs, config, ... }:
              {
                # system dependencies
                packages =
                  [
                    pkgs.git
                  ] ++ defaultSystemDeps;

                # R dependencies
                languages.r = {
                  enable = true;
                  package = pkgs.rWrapper.override {
                    packages =
                      with pkgs.rPackages;
                      [
                        here
                        tidyverse
                      ]
                      ++ defaultRPackages;
                  };
                };

                # python dependencies
                languages.python = {
                  enable = true;
                  version = "3.12";
                  uv.enable = true;
                  uv.sync.enable = true;
                };

                scripts = {
                  setup-jupyter.exec = ''
                    echo "Setting up kernels for Jupyter..."

                    echo "R kernel"
                    kernelsDir=.devenv/.jupyter/kernels

                    # Ensure an 'ir' folder exists in 'KernelsDir':
                    mkdir -p $kernelsDir/ir

                    # Copy the files using interpolation
                    cp -r ${pkgs.rPackages.IRkernel}/library/IRkernel/kernelspec/* $kernelsDir/ir

                    # Add write permission
                    chmod -R u+w $kernelsDir/ir
                    sed -i 's/"display_name": *"R"/"display_name": "R (devenv)"/' $kernelsDir/ir/kernel.json

                    # set up Jupyter to look for kernels in the '.jupyter' dir:
                    echo "Jupyter kernel R (devenv)  is ready."

                    uv run python -m ipykernel install --prefix="/tmp" --name="python" --display-name="Python (devenv)" > /dev/null 2>&1
                    cp -r /tmp/share/jupyter/kernels/python $kernelsDir/

                    echo "Jupyter kernel Python (devenv) is ready."

                  '';
                };

                processes = {
                  jupyter.exec = ''
                    setup-jupyter
                    uv run jupyter notebook --no-browser --ip="localhost" --IdentityProvider.token="" --ServerApp.password=""
                  '';
                };

                enterShell = ''
                  export UV_LINK_MODE="copy"
                  export JUPYTER_PATH="$PWD/.devenv/.jupyter"
                  export RETICULATE_PYTHON=$(uv run python -c "import sys; print(sys.executable)")
                '';

                # enterTest = '''';
              }
            )
          ];
        };
      }
    );
}
