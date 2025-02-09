{
  description = "Development environments for different projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };

      # Base Shell with shared cloud tools + common utilities
      baseShell = { extraPackages ? [ ], extraShellHook ? "" }: pkgs.mkShell {
        packages = with pkgs; [
          # Password managers
          #_1password-gui-beta - broken
          #_1password-cli - broken
          # bitwarden-desktop other arch
          # bitwarden-cli other arch
          # Core cli tools
          # Cloud tools
          terraform
          # Kubernetes
          certbot
          cosign
          kubectl
          k9s
          kubectx
          kustomize
          kube-score
          trivy
          # AWS
          awscli2
          aws-sam-cli
          ssm-session-manager-plugin
          eksctl
          # Node.js
          nodejs
          nodePackages_latest.aws-cdk
          nodePackages.cdktf-cli
          # Personal applications
          dbeaver-bin
          python39
        ] ++ extraPackages;
        shellHook = ''
          export SHELL=${pkgs.zsh}/bin/zsh

          # Start Zsh instead of Bash when entering nix develop
          if [ -z "$IN_NIX_SHELL" ]; then
            exec ${pkgs.zsh}/bin/zsh
          fi

          # Base cloud configurations
          export AWS_CONFIG_FILE="$HOME/matchi/repos/matchi-utils/aws/config"

          echo "Base environment loaded!"
          ${extraShellHook}
        '';
      };

    in
    {
      devShells.aarch64-darwin = {
        # Base Environment (automatically included in all others)
        base = baseShell { };

        # Java 8 WebApp Environment (inherits base settings)
        webapp = baseShell {
          extraPackages = with pkgs; [
            openjdk8
            groovy
            grails
          ];
          extraShellHook = ''
            export JAVA_HOME=${pkgs.openjdk8}/lib/openjdk
            export PATH=$JAVA_HOME/bin:$PATH

            echo "Java 8 WebApp environment loaded!"
          '';
        };

        # Personal Development Environment (inherits base settings)
        personal = baseShell {
          extraPackages = with pkgs; [ openjdk21 ];
          extraShellHook = ''
            export JAVA_HOME=${pkgs.openjdk21}/lib/openjdk
            export PATH=$JAVA_HOME/bin:$PATH
            echo "Personal environment loaded!"
          '';
        };

        # Golang Environment (inherits base settings)
        golang = baseShell {
          extraPackages = with pkgs; [
            go
            gosec
            golangci-lint
            go-tools
            hugo
            openapi-generator-cli
          ];
          extraShellHook = ''
            export GOPATH=$HOME/go
            export GOPRIVATE="github.com/matchiapp"
            export PATH=$GOPATH/bin:$PATH
            echo "Golang environment loaded!"
          '';
        };

        # Frontend Development Environment (inherits base settings)
        frontend = baseShell {
          extraPackages = with pkgs; [
            bun
            android-studio
          ];
          extraShellHook = ''
            export ANDROID_HOME=$HOME/Library/Android/sdk 
            export PATH=$PATH:$ANDROID_HOME/emulator
            export PATH=$PATH:$ANDROID_HOME/platform-tools
            echo "Android SDK environment loaded!"
          '';
        };

        # GitHub Workflows Development Environment (inherits base settings)
        github-workflows = baseShell {
          extraPackages = with pkgs; [
            act
            gh
          ];
          extraShellHook = ''
            echo "GitHub Workflows environment loaded!"
          '';
        };

        # GCP Development Environment (inherits base settings)
        gcp = baseShell {
          extraPackages = with pkgs; [
            google-cloud-sdk
            firebase-tools
          ];
          extraShellHook = ''
            echo "GCP environment loaded!"
          '';
        };
      };
    };
}
