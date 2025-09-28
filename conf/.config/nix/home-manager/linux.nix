{ inputs, lib, config, pkgs, phps, ... }:

{
  imports = [
    ./common.nix
  ];
  home.homeDirectory = "/home/${config.home.username}";

  home.packages = with pkgs; [
    gcc
    hackgen-font
    hackgen-nf-font
    xsel
  ];

  home.file.".xsessionrc" = {
    text = ''
      xset r rate 150 50
    '';
  };

  # home.file.".xprofile" = {
  #   text = ''
  #     xset r rate 150 50
  #   '';
  # };

}
