{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.aarch64-darwin.hello = nixpkgs.legacyPackages.aarch64-darwin.hello;
    packages.aarch64-darwin.default = self.packages.aarch64-darwin.hello;

    packages.aarch64-darwin.my-package = nixpkgs.legacyPackages.aarch64-darwin.buildEnv {
      name = "my-package-list";
      paths = [
        nixpkgs.legacyPackages.aarch64-darwin.git
        nixpkgs.legacyPackages.aarch64-darwin.curl
      ];
    };

  };
}
