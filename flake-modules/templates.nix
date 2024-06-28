{ self, inputs, ... }:
{
  flake.templates = {
    default = {
      path = ../templates/simple;
      description = "A simple nix flake template for getting started with nixvim";
    };
  };

  # The following adds the template flake's checks to the main (current) flake's checks.
  # It ensures that the template's own checks are successful.
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {};
}
