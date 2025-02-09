{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Use stable channel
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs"; # Ensure correct nixpkgs version
  };

  outputs = { self, nix-darwin, nixpkgs, mac-app-util }: # Include mac-app-util here
    let
      configuration = { pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;
        # Install CLI & GUI applications
        environment.systemPackages = with pkgs; [
          # Needed for macOS aliases
          mkalias
          # CLI tools
          neovim
          zsh # Ensure Zsh is installed
          zsh-powerlevel10k
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
          # GUI applications
          discord
        ];

        # Enable Touch ID authentication for sudo.
        security.pam.enableSudoTouchIdAuth = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Enable alternative shell support in nix-darwin.
        programs.zsh.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        system.stateVersion = 6;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      darwinConfigurations."Claess-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          mac-app-util.darwinModules.default # Ensure this is recognized
        ];
      };
    };
}
