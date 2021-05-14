{ lib, stdenv, fetchgit, buildGoModule, cmake, git, python3, curl, jq, go }:

let
  take = count : string : lib.concatStrings (lib.take count (lib.stringToCharacters string));

  pname = "trueblocks-core";
  version = "2021.05.01";

  repo = fetchgit {
    url = "https://github.com/TrueBlocks/${pname}.git";
    rev = "e7b6ce55d763181fdd1568fd299337e61c003d3e";
    sha256 = "sha256-JlHJrzIlxJfpqD+hR6WQbx48f8PlH1BE80jUmdf8szE=";
    deepClone = true;
  };

  # -- go subpackages --

  unchained = buildGoModule {
    inherit version;
    pname = "${pname}-unchained";
    src = "${repo}/src/go-apps/unchained";
    vendorSha256 = "1wwjv92b9xq80gl1fmxrda3lrrvxj1c8ga9y0y6qh8vnndfv2071";
    runVend = true;
  };
  flame = buildGoModule {
    inherit version;
    pname = "${pname}-flame";
    src = "${repo}/src/go-apps/flame";
    vendorSha256 = "0nzy4fcpgg4sppbzlji9jzilkr2ziybv3vld2f3pwmf2dsxan8xr";
  };
  findSig = buildGoModule {
    inherit version;
    pname = "${pname}-findSig";
    src = "${repo}/src/go-apps/findSig";
    vendorSha256 = "00f9ii6b627pwqyi0c97wmamw6yljc4fgnp2p68hw2g0g0bbbg5w";
    runVend = true;
  };
  blaze = buildGoModule {
    inherit version;
    pname = "${pname}-blaze";
    src = "${repo}/src/go-apps/blaze";
    vendorSha256 = "1rass18f37v269zwdfl0sf02dqknnaw8qibi7k70ajrmc736y8zn";
  };
  acctScrape2 = buildGoModule {
    inherit version;
    pname = "${pname}-acctScrape2";
    src = "${repo}/src/go-apps/acctScrape2";
    vendorSha256 = "0bsg817hwdhhy7p8dry37mrhsmx5kmwdzh3bdllp7qrmd3b2myw6";
  };

  # -- run cmake --

  cppModules = let
    repoName = "${pname}-${take 7 repo.rev}";
    srcRoot = "/build/${repoName}/src";
    buildRoot = "/build/${repoName}/build";
    dataRoot = "/build/${repoName}/data";
  in stdenv.mkDerivation {
    inherit pname version;

    src = repo;
    buildInputs = [
      cmake
      curl
      go
      jq
      python3
      git
    ];

    postUnpack = ''
      sed -i '/add_subdirectory (go-apps)/d' ${srcRoot}/CMakeLists.txt
    '';
    configurePhase = ''
      export XDG_DATA_HOME=${dataRoot}
      mkdir -p ${dataRoot}

      mkdir -p ${buildRoot}
      cd ${buildRoot}
      cmake ../src
    '';
    buildPhase = ''
      make
    '';
    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share

      cp -R ${dataRoot} $out/share

      cp -R /build/${repoName}/bin/* $out/bin
      rm -rf $out/bin/test
      rm -rf $out/bin/README.md
    '';
  };

in

  # -- merge outputs --

  stdenv.mkDerivation rec {
    inherit pname version;
    src = repo;

    installPhase = let
      bin = "$out/bin";
      share = "$out/share/trueblocks";
    in ''
      mkdir -p ${bin}
      mkdir -p ${share}

      cp ${unchained}/bin/* ${bin}
      cp ${flame}/bin/* ${bin}
      cp ${findSig}/bin/* ${bin}
      cp ${blaze}/bin/* ${bin}
      cp ${acctScrape2}/bin/* ${bin}
      cp -R ${cppModules}/bin/* ${bin}

      cp -R ${cppModules}/share/* ${share}
    '';

    meta = with lib; {
      homepage = "https://github.com/TrueBlocks/trueblocks-core";
      description = "Tooling for Ethereum blockchain analysis";
      license = with licenses; [ gpl3Plus ];
      maintainers = with maintainers; [ xwvvvvwx ];
    };
  }
