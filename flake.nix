{
  description = "tses - tmux session manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Read tses.sh and strip the shebang line
        scriptContent = builtins.readFile ./tses.sh;
        scriptBody = pkgs.lib.removePrefix ''
          #!/usr/bin/env bash
        '' scriptContent;
      in {
        packages = {
          tses = pkgs.writeShellApplication {
            name = "tses";
            runtimeInputs = with pkgs; [
              tmux
              fzf
              fd
              findutils
              gawk
              gnused
              gnugrep
              coreutils
            ];
            text = scriptBody;
          };
          default = self.packages.${system}.tses;
        };
      });
}
