{
  description = "Nix-darwin system flake for configuring macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
    zed-editor.url = "github:zed-industries/zed";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin, mac-app-util, nix-homebrew, zed-editor }:
    let
      username = "claeseklund";
      homeDir = "/Users/${username}"; # ✅ Ensure absolute path
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
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
            nix.settings.extra-substituters = [
              "https://zed.cachix.org"
            ];
            nix.settings.extra-trusted-public-keys = [
              "zed.cachix.org-1:W0gJVb6Bw5JZVf5GUUReBcsBMu+ECbVBfhCphMNzmFI="
            ];
            # security.pam.enableSudoTouchIdAuth = true;
            security.pam.services.sudo_local.touchIdAuth = true;

            environment.systemPackages = with pkgs; [
              mkalias
              imgcat
              ripgrep
              fzf
              watchexec
              bat
              fastfetch
              neovim
              zsh
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
              certbot
              cosign
              docker-compose
              docker
              # UI applications
              discord
              dbeaver-bin
              bruno
              vscode
              trivy
              bitwarden-desktop
              starship
              btop
              ncdu
              duf

              zed-editor.packages.aarch64-darwin.default
              pkgs-unstable.ghostty-bin
              pkgs-unstable.claude-code
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
