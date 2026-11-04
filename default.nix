{ pkgs ? import <nixpkgs> { } }:

let
  flake = builtins.getFlake (toString ./.);
in
flake.packages.${pkgs.system}.default
