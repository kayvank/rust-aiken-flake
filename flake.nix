{
  description = "rust-aiken-flake";
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;

        aikenpoc = pkgs.rustPlatform.buildRustPackage {
          name = "aikenpoc";
          buildInputs = with pkgs; [ openssl ];
          nativeBuildInputs = with pkgs; [ pkg-config openssl.dev ];

          src = pkgs.lib.cleanSourceWith { src = self; };
        };

        packages = {
          aikenpoc = aikenpoc;
          default = packages.aikenpoc;
        };

       overlays.default = final: prev: { aikenpoc = packages.aikenpoc; };

        gitRev = if (builtins.hasAttr "rev" self) then self.rev else "dirty";
      in {
        inherit packages overlays;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            toolchain
            openssl
            cargo-insta
            pkg-config
            eza
            rust-analyzer-unwrapped
            watchexec
            cowsay
            redis
            postgresql
            nodejs
            typescript
            deno
          ];
          shellHook = ''
            alias ls=eza
            alias find=fd
            echo "rust-dev" | cowsay
            set -o vi

            export PATH="~/.cargo/bin:$PATH"
            export DATABASE_URL='postgres://postgres:postgres@127.0.0.1:5432/newsletter'
            export POSTGRES_USER='postgres'
            export POSTGRES_PASSWORD='postgres'
            export POSTGRES_DB='newsletter'
            export APP_ENVIRONMENT=local
            export BLOCKFROST_PROJECT_ID="XXXXX" ## replace with actual key

            cargo install aiken --version 1.0.26-alpha
            cargo install --version 0.5.7 sqlx-cli --no-default-features --features postgres
            cargo install cargo-udeps
	          cargo install aiken --version 1.0.26-alpha
            cargo install bunyan
          '';
        };
      });
}
