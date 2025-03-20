{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager } @ inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.my-package =
        let
          customPkgs = import nixpkgs {
            inherit system;
          };
        in
        customPkgs.buildEnv {
          name = "my-package-list";
          paths = with customPkgs;
            [
              hello
              curl
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

      homeConfigurations = {
        myHomeConfig = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
          };
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./.config/home-manager/home.nix
          ];
        };
      };

    };

}
