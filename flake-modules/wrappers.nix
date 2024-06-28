{
  inputs,
  modules,
  getHelpers,
  self,
  ...
}:
let
  wrapperArgs = {
    inherit modules;
    inherit self;
    inherit getHelpers;
  };
in
{
  perSystem =
    {
      system,
      pkgs,
      pkgsUnfree,
      config,
      ...
    }:
    {
      _module.args = {
        makeNixvimWithModule = import ../wrappers/standalone.nix pkgs wrapperArgs;

        makeNixvimWithModuleUnfree = import ../wrappers/standalone.nix pkgsUnfree wrapperArgs;
      };

    };

  flake = {
    nixosModules = {
      nixvim = import ../wrappers/nixos.nix wrapperArgs;
      default = self.nixosModules.nixvim;
    };
    homeManagerModules = {
      nixvim = import ../wrappers/hm.nix wrapperArgs;
      default = self.homeManagerModules.nixvim;
    };
    nixDarwinModules = {
      nixvim = import ../wrappers/darwin.nix wrapperArgs;
      default = self.nixDarwinModules.nixvim;
    };
  };
}
