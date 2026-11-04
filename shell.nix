{ pkgs ? import <nixpkgs> { } }:

let
  flake = builtins.getFlake (toString ./.);
  devShell = flake.devShells.${builtins.currentSystem}.default;
in
devShell
