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
      nix-gl-host,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        kernelsDir = ".devenv/.jupyter/kernels";

        defaultSystemDeps = [
          # always system deps
          pkgs.git
          pkgs.gcc
          # weird build deps for rpy2
          pkgs.bzip2
          pkgs.icu
          pkgs.libdeflate
          pkgs.xz
          pkgs.zlib
          # # rpy2 deps end
        ];

        defaultRPackages = with pkgs.rPackages; [
          box
          reticulate
          svglite
          IRkernel
          jsonlite
          here
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
                  defaultSystemDeps
                  ++ [
                    pkgs.ffmpeg
                  ]
                  ++ pkgs.lib.lists.optionals pkgs.stdenv.isLinux [
                    nix-gl-host.defaultPackage.${system}
                  ];

                # R dependencies
                languages.r = {
                  enable = true;
                  package = pkgs.rWrapper.override {
                    packages =
                      with pkgs.rPackages;
                      [
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

                  '';
                };

                processes = {
                  jupyter.exec = ''
                    setup-jupyter
                    uv run jupyter notebook --no-browser --ip="localhost" --IdentityProvider.token="" --ServerApp.password=""
                  '';
                };

                enterShell = ''
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
