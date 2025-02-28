{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls.url = "github:zigtools/zls";
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ ];
        };
        zig = inputs.zig-overlay.packages.${system}.master;
        zls = inputs.zls.packages.${system}.zls.overrideAttrs {
          nativeBuildInputs = [ zig ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          shellHook = "nu";
          packages = with pkgs; [
            zig
            zls
            hotspot
            linuxKernel.packages.linux_latest_libre.perf
          ];
        };
      }
    );
}
