{
  description = "Nix-darwin system flake for configuring macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, mac-app-util, nix-homebrew }:
    let
      username = "claeseklund";
      homeDir = "/Users/${username}"; # ✅ Ensure absolute path
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations."Claess-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          # ✅ System-Wide nix-darwin Configuration
          {
            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = "nix-command flakes";
            security.pam.enableSudoTouchIdAuth = true;

            environment.systemPackages = with pkgs; [
              mkalias
              imgcat
              imagemagick
              fastfetch
              neovim
              zsh
              zsh-powerlevel10k
              zsh-completions
              yq
              jq
              wget
              curl
              git
              fswatch
              tree
              gnutls
              gnupg
              coreutils
              gnumake
              openssl
              discord
            ];

            programs.zsh.enable = true;
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.stateVersion = 6;
            nixpkgs.hostPlatform = "aarch64-darwin";
          }

          # ✅ nix-homebrew support
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              autoMigrate = true;
              enableRosetta = true;
            };
          }

          # ✅ mac-app-util support
          mac-app-util.darwinModules.default
        ];
      };
    };
}
