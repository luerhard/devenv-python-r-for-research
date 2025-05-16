final: prev: rec {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {

      # broken dependency of spacy, get newest version from PyPi
      wandb = pyprev.buildPythonPackage rec {
        pname = "wandb";
        version = "0.19.5";
        format = "wheel";
        src = builtins.fetchurl {
          url = "https://files.pythonhosted.org/packages/8a/30/8c495234e584ebcea92ec1d178897beeaf9798835bbb4f2b9a31c6533985/wandb-0.19.5-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          sha256 = "0f8be456cbe819e8202009cf4ac10a5a28141c4c6370f34b3f8cbd640c2dc8f9";
        };
        propagatedBuildInputs = [
          prev.python3.pkgs.click
          prev.python3.pkgs.docker-pycreds
          prev.python3.pkgs.gitpython
          prev.python3.pkgs.platformdirs
          prev.python3.pkgs.protobuf
          prev.python3.pkgs.psutil
          prev.python3.pkgs.pyyaml
          prev.python3.pkgs.requests
          prev.python3.pkgs.sentry-sdk_2
          prev.python3.pkgs.setproctitle
          prev.python3.pkgs.setuptools
        ];
      };

      # package not on nix-store
      multiprocessing-logging = pyprev.buildPythonPackage rec {
        pname = "multiprocessing-logging";
        version = "0.3.4";
        format = "wheel";
        src = builtins.fetchurl {
          url = "https://files.pythonhosted.org/packages/9e/fe/32bd864bcb604b0607924a4cf618ed267a0ef21ac9c3e255109256046e1f/multiprocessing_logging-0.3.4-py2.py3-none-any.whl";
          sha256 = "8a5be02b02edbd6fa6e3e89499af7680db69db9e2d8707fcd28d445fa248f23e";
        };
        propagatedBuildInputs = [ ];
      };

      # package not on nix-store
      silero-vad = pyprev.buildPythonPackage rec {
        pname = "silero-vad";
        version = "5.1.2";
        format = "wheel";
        src = builtins.fetchurl {
          url = "https://files.pythonhosted.org/packages/98/f7/5ae11d13fbb733cd3bfd7ff1c3a3902e6f55437df4b72307c1f168146268/silero_vad-5.1.2-py3-none-any.whl";
          sha256 = "93b41953d7774b165407fda6b533c119c5803864e367d5034dc626c82cfdf661";
        };
        propagatedBuildInputs = [
          prev.python3.pkgs.torch-bin
          prev.python3.pkgs.torchaudio-bin
          prev.python3.pkgs.onnxruntime
        ];
      };

      yt-dlp = pyprev.buildPythonPackage rec {
        pname = "yt-dlp";
        version = "2025-3-31";
        format = "wheel";
        src = builtins.fetchurl {
          url = "https://files.pythonhosted.org/packages/a8/bf/7b0affb8f163376309696cfd1c677818fa0969fbb9d88225087208799afe/yt_dlp-2025.3.31-py3-none-any.whl";
          sha256 = "8ecb3aa218a3bebe431119f513a8972b9b9d992edf67168c00ab92329a03baec";
        };
        propagatedBuildInputs = [
          prev.python3.pkgs.brotli
          prev.python3.pkgs.certifi
          prev.python3.pkgs.mutagen
          prev.python3.pkgs.pycryptodomex
          prev.python3.pkgs.requests
          prev.python3.pkgs.urllib3
          prev.python3.pkgs.websockets
        ];
      };

      # Fails to build from nix due to substrait v0.36.0 package
      ibis-framework = pyprev.buildPythonPackage rec {
        pname = "ibis-framework";
        version = "9.5.0";
        format = "wheel";
        src = builtins.fetchurl {
          url = "https://files.pythonhosted.org/packages/dd/a9/899888a3b49ee07856a0bab673652a82ea89999451a51fba4d99e65868f7/ibis_framework-9.5.0-py3-none-any.whl";
          sha256 = "145fe30d94f111cff332580c275ce77725c5ff7086eede93af0b371649d009c0";
        };
        propagatedBuildInputs = [
          prev.python3.pkgs.atpublic
          prev.python3.pkgs.parsy
          prev.python3.pkgs.python-dateutil
          prev.python3.pkgs.pytz
          prev.python3.pkgs.sqlglot
          prev.python3.pkgs.toolz
          prev.python3.pkgs.typing-extensions
          prev.python3.pkgs.duckdb
          prev.python3.pkgs.pyarrow
          prev.python3.pkgs.pyarrow-hotfix
          prev.python3.pkgs.numpy
          prev.python3.pkgs.packaging
          prev.python3.pkgs.pandas
          prev.python3.pkgs.rich
        ];
      };

    };
  };
}
