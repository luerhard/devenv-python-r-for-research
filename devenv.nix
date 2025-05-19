{ pkgs, config, nix-gl-host, ... }: {

  # system dependencies
  packages = [
    # always system deps
    pkgs.gcc
    pkgs.libdeflate
    pkgs.icu
    pkgs.git
    # custom system deps
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
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
      pip
      jupyter
      numpy
      pandas
      torch
      multiprocessing-logging
      spacy
      rpy2
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
    echo "copying files"
    cp -r ${pkgs.rPackages.IRkernel}/library/IRkernel/kernelspec/* $kernelsDir/ir

    # Add write permission
    echo "change perms"
    chmod -R u+w $kernelsDir/ir

    # set up Jupyter to look for kernels in the '.jupyter' dir:
    echo "Jupyter R kernel is ready."

    uv run python -m ipykernel install --prefix="/tmp" --name="python" --display-name="Python" > /dev/null 2>&1
    cp -r /tmp/share/jupyter/kernels/python kernelsDir/

    echo "Python (devenv) kernel is ready."

    uv run jupyter notebook --no-browser --ip="localhost" --IdentityProvider.token="" --ServerApp.password=""
    '';
  };

  enterShell = ''
    export JUPYTER_PATH="$PWD/.devenv/.jupyter"
    export RETICULATE_PYTHON=$(uv run python -c "import sys; print(sys.executable)")
  '';


}
