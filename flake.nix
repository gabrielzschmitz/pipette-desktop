{
  description = "Pipette - Vial-compatible keyboard configurator built with Tauri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        version = "0.5.1";
        pname = "pipette";

        src = pkgs.fetchurl {
          url = "https://github.com/darakuneko/pipette-desktop/releases/download/v${version}/Pipette-linux-x86_64.AppImage";
          sha256 = "sha256-bcsp4l88J6J0BGBy9aVKrB52MR7LZY37leA8GQB44HY=";
        };

        udevRules = pkgs.writeTextFile {
          name = "99-vial.rules";
          text = builtins.readFile ./scripts/99-vial.rules;
          destination = "/lib/udev/rules.d/99-vial.rules";
        };
      in
      {
        packages = {
          default = self.packages.${system}.${pname};
          ${pname} = pkgs.appimageTools.wrapType2 {
            inherit pname version src;

            extraPkgs = pkgs: with pkgs; [
              libgpg-error
              libgcrypt
              gpgme
              libsecret
            ];

            extraInstallCommands = ''
              mkdir -p $out/lib/udev/rules.d
              cp ${udevRules}/lib/udev/rules.d/99-vial.rules $out/lib/udev/rules.d/
              mkdir -p $out/share/applications
              cat > $out/share/applications/pipette.desktop << EOF
[Desktop Entry]
Name=Pipette
Comment=Vial-compatible keyboard configurator
Exec=pipette
Icon=pipette
Type=Application
Categories=Utility;Settings;HardwareSettings;
Keywords=keyboard;vial;qmk;keymap;
EOF
              mkdir -p $out/share/icons/hicolor/512x512/apps
              cp ${./build/icon.png} $out/share/icons/hicolor/512x512/apps/pipette.png 2>/dev/null || true
            '';

            meta = with pkgs.lib; {
              description = "Vial-compatible keyboard configurator";
              homepage = "https://github.com/darakuneko/pipette-desktop";
              license = licenses.gpl3Plus;
              platforms = platforms.linux;
              mainProgram = "pipette";
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            webkitgtk_4_1
            gtk3
            libsoup_3
            librsvg
            libayatana-appindicator
            xdotool
            openssl
            libudev-zero
            dbus
            glib
            cairo
            pango
            gdk-pixbuf
            glib-networking
          ];
          nativeBuildInputs = with pkgs; [
            nodejs_24
            pnpm
            rustc
            cargo
            pkg-config
            wrapGAppsHook3
            patchelf
            rust-analyzer
            clippy
            rustfmt
            typescript-language-server
            corepack
          ];

          shellHook = ''
            export COREPACK_ENABLE_STRICT=0
            export PNPM_IGNORE_PACKAGE_MANAGER_CHECK=1
            corepack enable >/dev/null 2>&1 || true
            echo "Pipette development environment"
            echo "Run 'pnpm install' and 'pnpm dev' to start development"
            echo ""
            echo "For USB keyboard access, make sure udev rules are installed:"
            echo "  sudo cp scripts/99-vial.rules /etc/udev/rules.d/"
            echo "  sudo udevadm control --reload-rules && sudo udevadm trigger"
            echo ""
            echo "On NixOS, add to configuration.nix:"
            echo "  services.udev.packages = with pkgs; [ pipette ];"
          '';
        };
      }
    );
}
