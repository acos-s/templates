{
  description = "Roblox Studio development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        mise = pkgs.mise;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ mise ];
          nativeBuildInputs = [ pkgs.dbus ];

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.dbus.lib}/lib:$LD_LIBRARY_PATH"

            # activate mise with shims for lightweight PATH injection
            # this lets mise read .mise.toml and manage tools without full env reload
            eval "$(mise activate bash --shims)"

            # ensure project tools are installed on shell entry
            mise install --quiet
          '';
        };
      }
    );
}
