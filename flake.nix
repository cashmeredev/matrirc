{
  description = "Matrirc development environment and package";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
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
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs.legacyPackages.${system} {
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages.matrirc = pkgs.matrirc;
        packages.default = self.packages.${system}.matrirc;
      }
    ) // {
      overlays.default = final: prev: {
        matrirc = final.rustPlatform.buildRustPackage {
          pname = "matrirc";
          version = "0.1.0";

          src = final.lib.cleanSource ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with final; [
            pkg-config
            gcc
            gnumake
          ];

          buildInputs = with final; [
            openssl
            zlib
            zlib.dev
            sqlite
            sqlite.dev
          ];

          SQLITE3_LIB_DIR = "${final.sqlite.out}/lib";
          SQLITE3_INCLUDE_DIR = "${final.sqlite.dev}/include";
          PKG_CONFIG_PATH = "${final.openssl.dev}/lib/pkgconfig";

          meta = with final.lib; {
            description = "Matrirc application";
            license = licenses.mit;
            maintainers = [ ];
          };
        };
      };

      nixosModules.default = { config, lib, pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
