{
  description = "Development environments for different projects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    openspec.url = "github:Fission-AI/OpenSpec";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, openspec }:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          unstable = import nixpkgs-unstable {
            inherit system;
          };

          # Base Shell with shared cloud tools + common utilities
          baseShell = { extraPackages ? [ ], extraShellHook ? "", logo ? "base" }: pkgs.mkShell {
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
              pnpm
              # nodePackages.aws-cdk
              # nodePackages.cdktf-cli # Broken build on 25.05
              # Personal applications
              gemini-cli
              openspec.packages.${system}.default
            ] ++ extraPackages;
            shellHook = ''
              NODE_GLOBAL_BIN="$HOME/.npm-global/bin"
              mkdir -p "$NODE_GLOBAL_BIN"
              export PATH="$NODE_GLOBAL_BIN:$PATH"

              # Helper: ensure global npm package(s) are installed
              # Usage: ensure_npm_pkg <command_to_check> <pkg1> [pkg2 ...]
              ensure_npm_pkg() {
                local cmd="$1"; shift
                if ! command -v "$cmd" &> /dev/null; then
                  echo "$cmd not found, installing globally..."
                  if npm install --global "$@" --prefix "$HOME/.npm-global"; then
                    echo "$cmd installed successfully."
                  else
                    echo "Error: Failed to install $cmd." >&2
                  fi
                else
                  echo "$cmd already installed."
                fi
              }

              ensure_npm_pkg jsonschema @sourcemeta/jsonschema
              ensure_npm_pkg cdk        aws-cdk
              ensure_npm_pkg cdktf      cdktf@0.20.12 cdktf-cli@0.20.12

              # Base cloud configurations
              export AWS_CONFIG_FILE="$HOME/workspace/matchi/matchi-utils/aws/config"

              ${extraShellHook}

              LOGO_WIDTH=$(( ''${COLUMNS:-80} * 20 / 100 ))
              clear
              fastfetch --kitty-direct $HOME/.config/nix/nix-dev-envs/logos/${logo}.png --logo-width $LOGO_WIDTH
            '';
          };
        in
        {
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

            echo "Java memory limit increased to 8G"

            echo "WebApp environment loaded with SDKMAN!"
          '';
          logo = "webapp";
        };

        # Golang Environment (inherits base settings)
        golang = baseShell {
          extraPackages = with pkgs; [
            go
            gosec
            unstable.golangci-lint
            go-tools
            hugo
            openapi-generator-cli
          ];
          extraShellHook = ''
            export GOPATH=$HOME/go
            export GOPRIVATE="github.com/matchiapp"
            export PATH=$GOPATH/bin:$PATH
          '';
          logo = "golang";
        };

        keycloak = baseShell {
          extraPackages = with pkgs; [
            # This shell is used for development of keycloak and should include all tools needed for development.
            # Golang
            go
            gosec
            unstable.golangci-lint
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
          '';
          logo = "keycloak";
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
          logo = "frontend";
        };

        # Combined Fullstack (Golang + Frontend + GCP + Personal) Environment
        fullstack = baseShell {
          extraPackages = with pkgs; [
            # From golang
            go
            gosec
            unstable.golangci-lint
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

          '';
          logo = "fullstack";
        };

        }
      );
    };
}

