{
  description = "Matrirc development environment and package";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    flake-utils.url = "github:numtide/flake-utils";
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
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.matrirc = pkgs.rustPlatform.buildRustPackage {
          pname = "matrirc";
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            gcc
            gnumake
          ];

          buildInputs = with pkgs; [
            openssl
            zlib
            zlib.dev
            sqlite
            sqlite.dev
          ];

          SQLITE3_LIB_DIR = "${pkgs.sqlite.out}/lib";
          SQLITE3_INCLUDE_DIR = "${pkgs.sqlite.dev}/include";
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

          meta = with pkgs.lib; {
            description = "Matrirc application";
            license = licenses.mit;
            maintainers = [ ];
          };
        };

        packages.default = self.packages.${system}.matrirc;

        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              packages = with pkgs; [
                git
                openssl
                pkg-config
                gcc
                gnumake
                zlib
                zlib.dev
                sqlite
                sqlite.dev
              ];

              languages.rust.enable = true;

              scripts.hello.exec = ''
                echo hello from $GREET
              '';

              env = {
                GREET = "devenv";
                SQLITE3_LIB_DIR = "${pkgs.sqlite.out}/lib";
                SQLITE3_INCLUDE_DIR = "${pkgs.sqlite.dev}/include";
              };

              enterShell = ''
                hello
                git --version
              '';

              enterTest = ''
                echo "Running tests"
                git --version | grep --color=auto "${pkgs.git.version}"
              '';
            }
          ];
        };

        packages.devenv-up = self.devShells.${system}.default.config.procfileScript;
        packages.devenv-test = self.devShells.${system}.default.config.test;
      }
    );
}
