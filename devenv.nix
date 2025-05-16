{
  pkgs,
  lib,
  config,
  inputs,
  system,
  ...
}:
let

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
    ];
  };
  kernelsDir = ".devenv/.jupyter/kernels";

in
{

  # load all overlays
  overlays = [
    (import ./nix/python-overlay.nix)
    (import ./nix/r-overlay.nix)
  ];

  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages =
    [
      pkgs.gcc
      pkgs.git
    ]
    ++ pkgs.lib.lists.optional pkgs.stdenv.isLinux [
      pkgs.nix-gl-host.defaultPackage.${"linux_x86-64"}
    ];

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    version = "3.12.2";
    uv.enable = true;
  };

  languages.r = {
    enable = true;
    package = rEnv;
  };

  # https://devenv.sh/processes/
  processes = {
    jupyter.exec = "uv run jupyter notebook --no-browser --ip='localhost' --ServerApp.token='' --ServerApp.password=''";
  };

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
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

  '';

  enterShell = ''
    setup-jupyter
    export JUPYTER_PATH="$PWD/.devenv/.jupyter"

    uv sync
    export RETICULATE_PYTHON=$(uv run python -c "import sys; print(sys.executable)")
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
    uv run pytest
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
