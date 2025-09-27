{ inputs, lib, config, pkgs, phps, ... }:


let
  username = "happy";
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./common.nix
  ];


}
