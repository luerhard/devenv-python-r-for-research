{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
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

        jupyterStart = pkgs.writeShellScriptBin "jupyter-start" ''

          echo "Setting up kernels for Jupyter..."

          echo "R kernel"
          kernelsDir=.venv/.jupyter/kernels

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

          uv run jupyter notebook --no-browser --ip="localhost" --IdentityProvider.token="" --ServerApp.password=""

        '';

        defaultSystemDeps =
          [
            # always system deps
            pkgs.gcc
            pkgs.R
            pkgs.uv
            # weird build deps for rpy2
            pkgs.bzip2
            pkgs.icu
            pkgs.libdeflate
            pkgs.xz
            pkgs.zlib # # rpy2 deps end
            jupyterStart
          ]
          ++ pkgs.lib.lists.optionals pkgs.stdenv.isLinux [
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
        defaultPackage = pkgs.mkShell {
          packages =
            [
              pkgs.git
            ]
            ++ defaultRPackages
            ++ defaultSystemDeps;
          shellHook = ''
            uv sync
            export JUPYTER_PATH="$PWD/.venv/.jupyter"
            export PYTHONPATH="$(pwd):$PYTHONPATH"
            export RETICULATE_PYTHON=$(which python)
          '';
        };
      }
    );
}
