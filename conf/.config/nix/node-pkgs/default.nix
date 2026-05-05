{ pkgs, nodejs ? pkgs.nodejs_24 }:

pkgs.importNpmLock.buildNodeModules {
  npmRoot = ./.;
  inherit nodejs;
}
