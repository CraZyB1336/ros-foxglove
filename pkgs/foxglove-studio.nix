{ lib, stdenv, fetchurl, dpkg, buildFHSEnv, writeShellScript }:
let
  version = "2.45.0";
  arch = {
    x86_64-linux = { deb = "amd64"; hash = lib.fakeHash; };
    aarch64-linux = { deb = "arm64"; hash = lib.fakeHash; };
  }.${stdenv.hostPlatform.system}
    or (throw "foxglove-studio: unsupported system ${stdenv.hostPlatform.system}");

  unwrapped = stdenv.mkDerivation {
    pname = "foxglove-studio-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://get.foxglove.dev/desktop/v${version}/foxglove-studio-${version}-linux-${arch.deb}.deb";
      inherit (arch) hash;
    };

    nativeBuildInputs = [ dpkg ];
    unpackPhase = ''
      dpkg-deb --fsys-tarfile $src | tar -x --no-same-owner --no-same-permissions
    '';
    installPhase = ''
      mkdir -p $out
      cp -r opt usr $out/
    '';
    dontStrip = true;
    dontPatchELF = true;
  };
in
buildFHSEnv {
  name = "foxglove-studio";

  targetpkgs = p: with p; [
    glib nss nspr cups dbus expat alsa-lib systemd udev
    gtk3 pango cairo at-spi2-core libdrm libxkbcommon
    libGL mesa (p.libgbm or p.mesa) vulkan-loader
    libsecret libnotify
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxcb xorg.libxkbfile
    xorg.libXScrnSaver xorg.libXtst xorg.libXi xorg.libXcursor
  ];

  runScript = writeShellScript "foxglove-run" ''
    bin=$(find ${unwrapped}/opt -maxdepth 2 -type f -perm -u+x -name 'foxglove*' | head -n1)
    exec "$bin" --no-sandbox "$@"
  '';

  extraInstallCommands = ''
    if [ -d ${unwrapped}/usr/share/applications ]; then
      mkdir -p $out/share
      cp -r ${unwrapped}/usr/share/icons $out/share/ 2>/dev/null || true
      mkdir -p $out/share/applications
      for f in ${unwrapped}/usr/share/applications/*.desktop; do
        sed 's|^Exec=.*|Exec=foxglove-studio %U|' "$f" > $out/share/applications/$(basename "$f")
      done
    fi
  '';

  meta = {
    description = "Foxglove visualization and debugging tool for robotics :D";
    homepage = "https://foxglove.dev";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "foxglove-studio";
  };
}