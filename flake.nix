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
    extra-substituters = "https://devenv.cachix.org";
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
              languages.python = {
                enable = true;
                version = "3.12.2";
                uv.enable = true;
              };

              languages.r = {
                enable = true;
                package = rEnv;
              };

              # https://devenv.sh/reference/options/
              packages =
                [
                  pkgs.gcc
                  pkgs.git
                 #]
                 #++ pkgs.lib.lists.optional pkgs.stdenv.isLinux [
                  nix-gl-host.defaultPackage.${system}
                ];

              scripts.setup-jupyter.exec = ''
                echo "Setting up R kernel for Jupyter..."

                # Ensure an 'ir' folder exists in 'KernelsDir':
                mkdir -p "${kernelsDir}/ir"

                # Copy the files using interpolation
                cp -r ${pkgs.rPackages.IRkernel}/library/IRkernel/kernelspec/* "${kernelsDir}/ir"

                # Add write permission
                chmod -R u+w "${kernelsDir}/ir"

                # set up Jupyter to look for kernels in the '.jupyter' dir:
                echo "Jupyter R kernel is ready."

                uv run python -m ipykernel install --prefix="/tmp" --name="python" --display-name="Python" 2> /dev/null
                cp -r /tmp/share/jupyter/kernels/python ${kernelsDir}/

                echo "Python (devenv) kernel is ready."
              '';

              processes = {
                jupyter.exec = "uv run jupyter notebook --no-browser --ip='localhost' --IdentityProvider.token='' --ServerApp.password=''";
              };

              enterShell = ''
                setup-jupyter
                export JUPYTER_PATH="$PWD/.devenv/.jupyter"
                export RETICULATE_PYTHON=$(uv run python -c "import sys; print(sys.executable)")
              '';

              enterTest = ''
                echo "Running tests"
                git --version | grep --color=auto "${pkgs.git.version}"
                uv run pytest
              '';
            }
          )
        ];
      };
    };
}
