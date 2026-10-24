{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {

  packages = [
    pkgs.cmake
    pkgs.pkg-config
    pkgs.quickshell
    pkgs.qt6.qtbase
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtwayland
    pkgs.qt6.qtmultimedia
  ];

  shellHook = ''
    export QML_IMPORT_PATH="${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:$PWD/build''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
  '';
}
