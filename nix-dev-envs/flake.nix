{
  description = "Development environments for different projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
          # Core cli tools
          gh
          fastfetch
          postgresql_17
          act
          bruno-cli
          restish
          # Cloud tools
          terraform
          # Kubernetes
          kubectl
          k9s
          kubectx
          kustomize
          kube-score
          trivy
          # AWS
          awscli2
          # aws-sam-cli
          ssm-session-manager-plugin
          eksctl
          # Node.js
          nodejs
          # nodePackages.aws-cdk
          # nodePackages.cdktf-cli # Broken build on 25.05
          # Personal applications
        ] ++ extraPackages;
        shellHook = ''
          export SHELL=${pkgs.zsh}/bin/zsh

          # Start Zsh instead of Bash when entering nix develop
          if [ -z "$IN_NIX_SHELL" ]; then
            exec ${pkgs.zsh}/bin/zsh
          fi

          NODE_GLOBAL_BIN="$HOME/.npm-global/bin"
          mkdir -p "$NODE_GLOBAL_BIN"
          export PATH="$NODE_GLOBAL_BIN:$PATH"

          # Install https://github.com/sourcemeta/jsonschema
          # This should allways be installed
          echo "Installing jsonschema..."
          npm install --g @sourcemeta/jsonschema --prefix "$HOME/.npm-global"

          echo "Checking for gemini"
          if ! command -v gemini &> /dev/null; then
            echo "gemini not found, installing globally with npm"
            sudo npm install --global @google/gemini-cli
            if [ $? -eq 0 ]; then
              echo "gemini installed successfully."
            else
              echo "Error: Failed to install gemini." >&2
            fi
          else
            echo "gemini already installed."
          fi

          # manually install aws-cdk
          echo "Checking for aws-cdk..."
          if ! command -v cdk &> /dev/null; then
            echo "aws-cdk not found, installing globally with npm..."
            npm install --global aws-cdk --prefix "$HOME/.npm-global"
            if [ $? -eq 0 ]; then
              echo "aws-cdk installed successfully."
            else
              echo "Error: Failed to install aws-cdk." >&2
            fi
          else
            echo "aws-cdk already installed."
          fi

          # Install cdktf-cli manually if not found
          echo "Checking for cdktf-cli..."
          if ! command -v cdktf &> /dev/null; then
            echo "cdktf-cli not found, installing globally with npm..."
            npm install cdktf@0.20.12 --global --prefix "$HOME/.npm-global"
            npm install --global cdktf-cli@0.20.12 --prefix "$HOME/.npm-global"
            if [ $? -eq 0 ]; then
              echo "cdktf-cli installed successfully."
            else
              echo "Error: Failed to install cdktf-cli." >&2
            fi
          else
            echo "cdktf-cli already installed."
          fi

          # Base cloud configurations
          export AWS_CONFIG_FILE="$HOME/matchi/repos/matchi-utils/aws/config"

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
            sdk install grails 3.3.18

            # Set default versions
            sdk use java 8.0.312-zulu
            sdk use groovy 2.5.13
            sdk use grails 3.3.18

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

            clear
            fastfetch --iterm /Users/claeseklund/.config/nix/nix-dev-envs/gopher.png --logo-width 50 --logo-height 25
          '';
        };

        keycloak = baseShell {
          extraPackages = with pkgs; [
            # This shell is used for development of keycloak and should include all tools needed for development.
            # Golang
            go
            gosec
            golangci-lint
            go-tools

            # Frontend tools
            yarn
            bun

            # Java
            jdk21_headless
            gradle_8
            gradle-completion
          ];
          extraShellHook = ''
            export GOPRIVATE="github.com/matchiapp"

            clear
            fastfetch --iterm /Users/claeseklund/.config/nix/nix-dev-envs/kcTerm.png --logo-width 50 --logo-height 25
          '';
        };

        # Frontend Development Environment (inherits base settings)
        frontend = baseShell {
          extraPackages = with pkgs; [
            bun
            yarn
            # android-studio
          ];
          extraShellHook = ''
            export ANDROID_HOME=$HOME/Library/Android/sdk
            export PATH=$PATH:$ANDROID_HOME/emulator
            export PATH=$PATH:$ANDROID_HOME/platform-tools
          '';
        };

        # Combined Fullstack (Golang + Frontend + GCP + Personal) Environment
        fullstack = baseShell {
          extraPackages = with pkgs; [
            # From golang
            go
            gosec
            golangci-lint
            go-tools
            hugo
            openapi-generator-cli
            # From frontend
            bun
            yarn
            # android-studio (if needed, uncomment)
            # From GCP
            google-cloud-sdk
            firebase-tools
          ];
          extraShellHook = ''
            # From golang
            export GOPATH=$HOME/go
            export GOPRIVATE="github.com/matchiapp"
            export PATH=$GOPATH/bin:$PATH

            # From frontend
            export ANDROID_HOME=$HOME/Library/Android/sdk
            export PATH=$PATH:$ANDROID_HOME/emulator
            export PATH=$PATH:$ANDROID_HOME/platform-tools

            # Java needed for GCP and Andriod building
            export SDKMAN_DIR="$HOME/.sdkman"
            if [ ! -d "$SDKMAN_DIR" ]; then
              echo "Installing SDKMAN!..."
              curl -s "https://get.sdkman.io" | bash
            fi

            # Initialize SDKMAN!
            source "$SDKMAN_DIR/bin/sdkman-init.sh"
            sdk install java 21.0.7-amzn
            sdk use java 21.0.7-amzn

            # From GCP
            # No specific shell hooks were defined in the original GCP environment,
            # but if there were, they would be added here.

            clear
            # You can choose one of the fastfetch logos or combine them, or remove it.
            # For example, using the gopher logo:
            fastfetch --logo-width 50 --logo-height 25
            echo "Fullstack (Golang + Frontend + GCP + Personal) environment loaded!"
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
      };
    };
}

