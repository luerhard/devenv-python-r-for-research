final: prev: {
  rPackages = prev.rPackages.override {
    overrides = {
      curl = prev.rPackages.curl.overrideDerivation (attrs: {
        version = "6.2.2";
        src = prev.fetchurl {
          url = "https://cran.r-project.org/src/contrib/curl_6.2.2.tar.gz";
          sha256 = "sha256-rRfdsHLPuOrFswmCSmN+eSdHR8fyd58kgZHy4dJ23Dk=";
        };
      });
    };
  };
}
