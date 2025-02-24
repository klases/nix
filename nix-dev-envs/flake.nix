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
          fastfetch
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
          # TODO: add this back when nix packages support a later versions of aws-cdk
          # nodePackages_latest.aws-cdk 
          nodePackages.cdktf-cli
          # Personal applications
          dbeaver-bin
        ] ++ extraPackages;
        shellHook = ''
          export SHELL=${pkgs.zsh}/bin/zsh

          # Start Zsh instead of Bash when entering nix develop
          if [ -z "$IN_NIX_SHELL" ]; then
            exec ${pkgs.zsh}/bin/zsh
          fi

          CDKVERSION="2.178.2"

          NODE_GLOBAL_BIN="$HOME/.npm-global/bin"
          mkdir -p "$NODE_GLOBAL_BIN"
          export PATH="$NODE_GLOBAL_BIN:$PATH"

          if ! command -v cdk &> /dev/null || [[ "$(cdk --version)" != "2.178.2 (build *)" ]]; then
            echo "Installing AWS CDK $CDKVERSION..."
            npm install -g aws-cdk@$CDKVERSION --prefix "$HOME/.npm-global"
          fi

          # Install https://github.com/sourcemeta/jsonschema
          # This should allways be installed
          echo "Installing jsonschema..."
          npm install --g @sourcemeta/jsonschema --prefix "$HOME/.npm-global"

          # Base cloud configurations
          export AWS_CONFIG_FILE="$HOME/matchi/repos/matchi-utils/aws/config"

          clear
          fastfetch --iterm /Users/claeseklund/.config/nix/nix-dev-envs/gopher.png --logo-width 50 --logo-height 25
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
          ];
          extraShellHook = ''
            export SDKMAN_DIR="$HOME/.sdkman"
            if [ ! -d "$SDKMAN_DIR" ]; then
              echo "Installing SDKMAN!..."
              curl -s "https://get.sdkman.io" | bash
            fi

            # Initialize SDKMAN!
            source "$SDKMAN_DIR/bin/sdkman-init.sh"

            # Install required versions (only if not already installed)
            sdk install java 8.0.312-zulu
            sdk install groovy 2.5.13
            sdk install grails 2.5.6

            # Set default versions
            sdk use java 8.0.312-zulu
            sdk use groovy 2.5.13
            sdk use grails 2.5.6

            # Increase Java memory limit
            export JAVA_TOOL_OPTIONS="-Xmx8G"

            export GRAILS_HOME="$HOME/.sdkman/candidates/grails/current"

            SPRINGLOADED_JAR="$GRAILS_HOME/lib/org.springframework/springloaded/jars/springloaded-1.2.4.RELEASE.jar"
            if [ ! -f "$SPRINGLOADED_JAR" ]; then
              echo "Patching Springloaded module..."
              mkdir -p "$(dirname "$SPRINGLOADED_JAR")"
              curl -sL "https://repo1.maven.org/maven2/org/springframework/springloaded/1.2.4.RELEASE/springloaded-1.2.4.RELEASE.jar" -o "$SPRINGLOADED_JAR"
              chmod +r "$SPRINGLOADED_JAR"
            fi

            alias runIdeaWebapp='cd "$HOME/matchi/repos/webapp" && ./run.sh "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" > /dev/null 2>&1 &'

            echo "Java memory limit increased to 8G"

            echo "WebApp environment loaded with SDKMAN!"
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
          '';
        };

        # Frontend Development Environment (inherits base settings)
        frontend = baseShell {
          extraPackages = with pkgs; [
            bun
            # android-studio
          ];
          extraShellHook = ''
            # export ANDROID_HOME=$HOME/Library/Android/sdk 
            # export PATH=$PATH:$ANDROID_HOME/emulator
            # export PATH=$PATH:$ANDROID_HOME/platform-tools
          '';
        };

        # GitHub Workflows Development Environment (inherits base settings)
        github-workflows = baseShell {
          extraPackages = with pkgs; [
            act
            gh
          ];
          extraShellHook = ''
          '';
        };

        # GCP Development Environment (inherits base settings)
        gcp = baseShell {
          extraPackages = with pkgs; [
            google-cloud-sdk
            firebase-tools
          ];
          extraShellHook = ''
          '';
        };
      };
    };
}
