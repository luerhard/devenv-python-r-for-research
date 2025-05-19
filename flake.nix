{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs-python.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    nix-gl-host.url = "github:numtide/nix-gl-host";
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
      nix-gl-host,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      rEnv = pkgs.rWrapper.override {
        packages = with pkgs.rPackages; [
          # always deps
          box
          reticulate
          svglite
          tidyverse
          IRkernel
          jsonlite
          here
          languageserver
          lintr
        ];
      };
      kernelsDir = ".devenv/.jupyter/kernels";

    in
    {
      packages.${system}.devenv-up = self.devShells.${system}.default.config.procfileScript;

      devShells.${system}.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          (
            { pkgs, config, ... }:
            {
              # system dependencies
              packages =
                [
                  # always system deps
                  pkgs.gcc
                  pkgs.glibcLocales
                  # weird build deps for rpy2
                  pkgs.libdeflate
                  pkgs.zlib
                  pkgs.xz
                  pkgs.bzip2
                  pkgs.libdeflate
                  pkgs.icu
                  # rpy2 deps end
                  pkgs.git
                  # project specific deps below
                ]
                ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
                  nix-gl-host.defaultPackage.${pkgs.system}
                ];

              # R dependencies
              languages.r = {
                enable = true;
                package = pkgs.rWrapper.override {
                  packages = with pkgs.rPackages; [
                    # always deps
                    box
                    reticulate
                    svglite
                    tidyverse
                    IRkernel
                    jsonlite
                    here
                    languageserver
                    lintr
                    # custom deps

                  ];
                };
              };

              # python dependencies
              languages.python = {
                enable = true;
                version = "3.12";
                venv.enable = true;
                venv.requirements = ''
                  # always deps
                  pip
                  jupyter
                  rpy2
                  # project-specific deps below
                  numpy
                  pandas
                  torch
                  multiprocessing-logging
                  spacy
                '';
                uv.enable = true;
              };

              processes = {
                jupyter.exec = ''

                  echo "Setting up R kernel for Jupyter..."

                  kernelsDir=.devenv/.jupyter/kernels

                  # Ensure an 'ir' folder exists in 'KernelsDir':
                  echo "Ensuring folder exists"
                  mkdir -p $kernelsDir/ir

                  # Copy the files using interpolation
                  cp -r ${pkgs.rPackages.IRkernel}/library/IRkernel/kernelspec/* $kernelsDir/ir

                  # Add write permission
                  chmod -R u+w $kernelsDir/ir

                  # set up Jupyter to look for kernels in the '.jupyter' dir:
                  echo "Jupyter R kernel is ready."

                  uv run python -m ipykernel install --prefix="/tmp" --name="python" --display-name="Python" > /dev/null 2>&1
                  cp -r /tmp/share/jupyter/kernels/python $kernelsDir/

                  echo "Python (devenv) kernel is ready."

                  uv run jupyter notebook --no-browser --ip="localhost" --IdentityProvider.token="" --ServerApp.password=""
                '';
              };

              enterShell = ''
                export JUPYTER_PATH="$PWD/.devenv/.jupyter"
                export RETICULATE_PYTHON=$(uv run python -c "import sys; print(sys.executable)")
              '';

              enterTest = ''
                echo "THIS IS MY ACTUAL CODE THAT WOULD RUN: (IS CUDA AVAILABLE?)"
                nixglhost uv run python -c "import torch; print(torch.cuda.is_available())"
                echo "OWN CODE DONE"
              '';
            }
          )
        ];
      };
    };
}
