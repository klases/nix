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
      system = "aarch64-darwin";
      username = "claeseklund";
      homeDir = "/Users/${username}"; # ✅ Ensure absolute path
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
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
              gnused
              openssl
              python3
              certbot
              cosign
              docker-compose
              docker
              # UI applications
              discord
              dbeaver-bin
              bruno
              trivy
              bitwarden-desktop
              bitwarden-cli
              starship
              btop
              ncdu
              duf

              zed-editor.packages.${system}.default
              pkgs-unstable.ghostty-bin
              pkgs-unstable.claude-code
              mas
            ];

            programs.zsh.enable = true;
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.primaryUser = username;
            system.stateVersion = 6;
            nixpkgs.hostPlatform = system;
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

          # ✅ Declarative Homebrew package management
          {
            homebrew = {
              enable = true;
              casks = [
                "1password"
                "arc"
                "bartender"
                "displaylink"
                "google-chrome"
                "nordvpn"
                "notion"
                "orbstack"
                "zoom"
              ];
              masApps = {
                "Be Focused"          = 973134470;
                "BetterSnapTool"      = 417375580;
                "Disk Space Analyzer" = 446243721;
                "GarageBand"          = 682658836;
                "iMovie"              = 408981434;
                "Keynote"             = 409183694;
                "Numbers"             = 409203825;
                "Pages"               = 409201541;
                "Slack"               = 803453959;
                "WireGuard"           = 1451685025;
              };
            };
          }

          # ✅ mac-app-util support
          mac-app-util.darwinModules.default
        ];
      };
    };
}
