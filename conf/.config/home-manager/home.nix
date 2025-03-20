{ inputs
, lib
, config
, pkgs
, ...
}:
let
  username = "toyama";
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    packages = with pkgs; [
      bat
      fd
      ripgrep
      tree
    ];
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.05";
  };


  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "toyama";
      userEmail = "toyama@toyama";
    };
  };



}
