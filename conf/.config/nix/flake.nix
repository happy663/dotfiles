{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, neovim-nightly-overlay }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system}.extend (
        neovim-nightly-overlay.overlays.default
      );
    in
    {

      packages.${system}.my-package = pkgs.buildEnv {
        name = "my-package-list";
        paths = with pkgs;
          [
            hello
            curl
          ]
          ++ [
            neovim
          ];
      };


      apps.${system}.update = {
        type = "app";
        program = toString
          (pkgs.writeShellScript "update-script" ''
            set -e
            echo "Updating flake..."
            nix flake update
            echo "Update profile"
            nix profile upgrade my-packages
            echo "Update complete"

          '');

      };
    };

}
