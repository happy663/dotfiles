{ inputs, lib, config, pkgs, phps, ... }:

{
  imports = [
    ./common.nix
  ];
  home.homeDirectory = "/Users/${config.home.username}";
  home.packages = with pkgs;[
    terminal-notifier
  ];
}
