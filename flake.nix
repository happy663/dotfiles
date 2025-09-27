{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # PHP 7.4などのレガシーPHPバージョンのリポジトリを追加
    phps = {
      url = "github:fossar/nix-phps";
      # nixpkgsを共有して一貫性を保つ
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, phps } @ inputs:
    let
      system = {
        darwin = "aarch64-darwin";
        linux = "x86_64-linux";
      };
      darwinPkgs = nixpkgs.legacyPackages.${system.darwin};
      linuxPkgs = nixpkgs.legacyPackages.${system.linux};
    in
    {
      apps.${system.darwin}.update = {
        type = "app";
        program = toString
          (darwinPkgs.writeShellScript "update-script" ''
            set -e
            echo "Updating flake..."
            nix flake update
            echo "Updating home-manager..."
            nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-darwin
            echo "Update complete"
            sudo nix run nix-darwin -- switch --flake .#happy-darwin
          '');
      };

      apps.${system.linux}.update = {
        type = "app";
        program = toString
          (linuxPkgs.writeShellScript "update-script" ''
            set -e
            echo "Updating flake..."
            nix flake update
            echo "Updating home-manager..."
            nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig-linux
            echo "Update complete"
          '');
      };


      homeConfigurations = {

        myHomeConfig-darwin = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = system.darwin;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
            # phpsパッケージを渡す
            inherit phps;
          };
          modules = [
            ./conf/.config/nix/home-manager/darwin.nix
          ];
        };

        myHomeConfig-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = system.linux;
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
            inherit phps;
          };
          modules = [
            ./conf/.config/nix/home-manager/linux.nix
          ];
        };

      };

      darwinConfigurations.happy-darwin = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [ ./conf/.config/nix/nix-darwin/default.nix ];
      };


    };
}
