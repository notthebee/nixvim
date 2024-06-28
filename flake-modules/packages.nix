{
  perSystem =
    {
      pkgsUnfree,
      config,
      rawModules,
      helpers,
      ...
    }:
    {
      packages = import ../docs {
        inherit rawModules helpers;
        # Building the docs evaluates each plugin's default package, some of which are unfree
        pkgs = pkgsUnfree;
      };

      # Test that all packages build fine when running `nix flake check`.
    };
}
