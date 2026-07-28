{
  description = "The Laravel language server.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = laravel-lsp;

          laravel-lsp = pkgs.callPackage (
            {
              lib,
              stdenvNoCC,
              fetchurl,
              php,
              makeBinaryWrapper,
            }:
            stdenvNoCC.mkDerivation (finalAttrs: {
              pname = "laravel-lsp";
              version = "0.0.28";

              src = ./builds/laravel-lsp;

              dontUnpack = true;

              nativeBuildInputs = [ makeBinaryWrapper ];

              installPhase = ''
                runHook preInstall

                install -Dm644 $src $out/share/laravel-lsp/laravel-lsp.phar
                makeWrapper ${lib.getExe php} $out/bin/laravel-lsp \
                  --add-flags "$out/share/laravel-lsp/laravel-lsp.phar"

                runHook postInstall
              '';

              meta = {
                description = "The Laravel language server";
                homepage = "https://github.com/laravel/lsp";
                license = lib.licenses.mit;
                sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
                mainProgram = "laravel-lsp";
                platforms = lib.platforms.unix;
              };
            })
          ) { };
        }
      );

      overlays.default = final: prev: {
        laravel-lsp = self.packages.${final.stdenv.hostPlatform.system}.laravel-lsp;
      };
    };
}
