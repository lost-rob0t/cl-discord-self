{
  description = "cl-discord-self development and deterministic Phase 0 checks";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/148bab9c1c3c53136ecb44a6ea356a0ed5b39b06";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = function:
        nixpkgs.lib.genAttrs systems
          (system: function (import nixpkgs { inherit system; }));
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            sbcl
            gcc
            gnumake
            pkg-config
            jq
            python3
          ];
        };
      });

      checks = forAllSystems (pkgs: {
        header-smoke = pkgs.runCommand "cldiscordcurl-header-smoke" {
          nativeBuildInputs = [ pkgs.gcc ];
        } ''
          cat > smoke.c <<'EOF'
          #include "${self}/native/include/cldiscordcurl.h"
          _Static_assert(CDC_ABI_VERSION == 1u, "ABI version must be one");
          _Static_assert(CDC_ERR_INTERNAL_NATIVE_FAILURE < 0,
                         "stable errors must be negative");
          int main(void) {
            cdc_runtime_options options = {0};
            options.abi_version = CDC_ABI_VERSION;
            return options.abi_version == 1u ? 0 : 1;
          }
          EOF
          cc -std=c11 -Wall -Wextra -Werror -pedantic \
            -fsyntax-only smoke.c
          touch "$out"
        '';

        json-schemas = pkgs.runCommand "cl-discord-self-json-schemas" {
          nativeBuildInputs = [ pkgs.python3 ];
        } ''
          python - <<'PY'
          import json
          from pathlib import Path

          root = Path("${self}/schemas")
          schemas = sorted(root.glob("*.schema.json"))
          if not schemas:
              raise SystemExit("no JSON schemas found")

          for path in schemas:
              with path.open("r", encoding="utf-8") as stream:
                  schema = json.load(stream)
              if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
                  raise SystemExit(f"unexpected schema dialect: {path}")
          PY
          touch "$out"
        '';

        asdf-smoke = pkgs.runCommand "cl-discord-self-asdf-smoke" {
          nativeBuildInputs = [ pkgs.sbcl ];
        } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          cp -R "${self}" source
          chmod -R u+w source
          cd source
          sbcl --noinform --non-interactive \
            --eval '(require :asdf)' \
            --eval '(asdf:load-asd (truename "cl-discord-self.asd"))' \
            --eval '(asdf:load-system "cl-discord-self")' \
            --eval '(asdf:test-system "cl-discord-self")'
          touch "$out"
        '';
      });
    };
}
