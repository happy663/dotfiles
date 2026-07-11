{ inputs, lib, config, pkgs,  ... }:

{
  imports = [
    ./common.nix
  ];
  home.homeDirectory = "/Users/${config.home.username}";
  home.packages = with pkgs;[
    terminal-notifier
    # neovim-nightly-overlay 由来 (flake.nix の overlays で適用済み)
    neovim
  ];

  home.file."Library/Fonts/akkurat.ttf".source = ../../fonts/akkurat.ttf;
}
