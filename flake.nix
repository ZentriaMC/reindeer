{
  description = "Generate Buck build rules for Rust crates (Zentria fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # Zentria: a from-source package, so the fork can be pinned the way
        # nixpkgs' prebuilt reindeer is consumed. Consumers that need the
        # patches -- DEP_<LINKS>_* propagation, [[cxx_library]] fixups on crates
        # without build scripts -- take this as a flake input instead of
        # pkgs.reindeer, and their flake.lock records the exact revision.
        packages.reindeer = pkgs.rustPlatform.buildRustPackage {
          pname = "reindeer";
          version = "2026.09.24.00-zentria";

          src = pkgs.lib.cleanSource ./.;
          cargoLock.lockFile = ./Cargo.lock;

          # Same inputs nixpkgs builds it with: the -sys crates it pulls
          # (curl, libgit2, libssh2, zlib) all vendor and build their own.
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];

          # rlimit::tests::raise_does_not_lower_limit compares the file
          # descriptor limit before and after raising it, and fails wherever the
          # sandbox hands back a lower ceiling than the hard limit says -- macOS
          # is one such place. It fails the same way on upstream, unpatched.
          doCheck = false;

          meta = {
            description = "Generate Buck build rules for Rust crates (Zentria fork)";
            mainProgram = "reindeer";
          };
        };
        packages.default = self.packages.${system}.reindeer;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          packages = [ pkgs.cargo pkgs.rustc pkgs.clippy pkgs.rustfmt ];
        };
      });
}
