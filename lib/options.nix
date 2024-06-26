{
  lib,
  nixvimTypes,
  nixvimUtils,
}:
with lib;
with nixvimUtils;
rec {
  # Creates an option with a nullable type that defaults to null.
  mkNullOrOption' =
    {
      type,
      default ? null,
      ...
    }@args:
    lib.mkOption (
      args
      // {
        type = lib.types.nullOr type;
        inherit default;
      }
    );
  mkNullOrOption = type: description: mkNullOrOption' { inherit type description; };

  mkCompositeOption' =
    { options, ... }@args:
    mkNullOrOption' (
      (filterAttrs (n: _: n != "options") args) // { type = types.submodule { inherit options; }; }
    );
  mkCompositeOption = description: options: mkCompositeOption' { inherit description options; };

  mkNullOrStr' = args: mkNullOrOption' (args // { type = with nixvimTypes; maybeRaw str; });
  mkNullOrStr = description: mkNullOrStr' { inherit description; };

  mkNullOrLua' =
    args:
    mkNullOrOption' (
      args
      // {
        type = nixvimTypes.strLua;
        apply = mkRaw;
      }
    );
  mkNullOrLua = description: mkNullOrLua' { inherit description; };

  mkNullOrLuaFn' =
    args:
    mkNullOrOption' (
      args
      // {
        type = nixvimTypes.strLuaFn;
        apply = mkRaw;
      }
    );
  mkNullOrLuaFn = description: mkNullOrLua' { inherit description; };

  mkNullOrStrLuaOr' =
    { type, ... }@args:
    mkNullOrOption' (
      args
      // {
        type = with nixvimTypes; either strLua type;
        apply = v: if isString v then mkRaw v else v;
      }
    );
  mkNullOrStrLuaOr = type: description: mkNullOrStrLuaOr' { inherit type description; };

  mkNullOrStrLuaFnOr' =
    { type, ... }@args:
    mkNullOrOption' (
      args
      // {
        type = with nixvimTypes; either strLuaFn type;
        apply = v: if isString v then mkRaw v else v;
      }
    );
  mkNullOrStrLuaFnOr = type: description: mkNullOrStrLuaFnOr' { inherit type description; };

  defaultNullOpts =
    let
      # Convert `defaultNullOpts`-style arguments into normal `mkOption`-style arguments,
      # i.e. moves `default` into `description` using `defaultNullOpts.mkDesc`
      convertArgs =
        { default, description, ... }@args:
        (
          args
          // {
            default = null;
            description = defaultNullOpts.mkDesc default description;
          }
        );
    in
    rec {
      /**
        Build a description with a plugin default.

        The [default] can be any value, and it will be formatted using `lib.generators.toPretty`.

        If [default] is a String, it will not be formatted.
        This behavior will likely change in the future.

        # Example
        ```nix
        mkDesc 1 "foo"
        => ''
          foo

          Plugin default: `1`
        ''
        ```

        # Type
        ```
        mkDesc :: Any -> String -> String
        ```

        # Arguments
        - [default] The plugin's default
        - [desc] The option's description
      */
      mkDesc =
        default: desc:
        let
          # Assume a string default is already formatted as intended,
          # historically strings were the only type accepted here.
          # TODO deprecate this behavior so we can properly quote strings
          defaultString = if isString default then default else generators.toPretty { } default;
          defaultDesc =
            "_Plugin default:_"
            + (
              # Detect whether `default` is multiline or inline:
              if hasInfix "\n" defaultString then "\n\n```nix\n${defaultString}\n```" else " `${defaultString}`"
            );
        in
        if desc == "" then
          defaultDesc
        else
          ''
            ${desc}

            ${defaultDesc}
          '';

      mkNullable' = { default, description, ... }@args: mkNullOrOption' (convertArgs args);
      mkNullable =
        type: default: description:
        mkNullable' { inherit type default description; };

      mkNullableWithRaw' =
        { type, ... }@args: mkNullable' (args // { type = nixvimTypes.maybeRaw type; });
      mkNullableWithRaw =
        type: default: description:
        mkNullableWithRaw' { inherit type default description; };

      mkStrLuaOr' = { default, description, ... }@args: mkNullOrStrLuaOr' (convertArgs args);
      mkStrLuaOr =
        type: default: description:
        mkStrLuaOr' { inherit type default description; };

      mkStrLuaFnOr' = { default, description, ... }@args: mkNullOrStrLuaFnOr' (convertArgs args);
      mkStrLuaFnOr =
        type: default: description:
        mkStrLuaFnOr' { inherit type default description; };

      mkLua' = { default, description, ... }@args: mkNullOrLua' (convertArgs args);
      mkLua = default: description: mkLua' { inherit default description; };

      mkLuaFn' = { default, description, ... }@args: mkNullOrLuaFn' (convertArgs args);
      mkLuaFn = default: description: mkLuaFn' { inherit default description; };

      mkNum' = args: mkNullableWithRaw' (args // { type = types.number; });
      mkNum = default: description: mkNum' { inherit default description; };
      mkInt' = args: mkNullableWithRaw' (args // { type = types.int; });
      mkInt = default: description: mkNum' { inherit default description; };
      # Positive: >0
      mkPositiveInt' = args: mkNullableWithRaw' (args // { type = types.ints.positive; });
      mkPositiveInt = default: description: mkPositiveInt' { inherit default description; };
      # Unsigned: >=0
      mkUnsignedInt' = args: mkNullableWithRaw' (args // { type = types.ints.unsigned; });
      mkUnsignedInt = default: description: mkUnsignedInt' { inherit default description; };
      mkBool' = args: mkNullableWithRaw' (args // { type = types.bool; });
      mkBool = default: description: mkBool' { inherit default description; };
      mkStr' =
        { default, ... }@args:
        mkNullableWithRaw' (
          args
          // {
            # TODO we should remove this once `mkDesc` no longer has a special case
            default = generators.toPretty { } default;
            type = types.str;
          }
        );
      mkStr = default: description: mkStr' { inherit default description; };

      mkAttributeSet' = args: mkNullable' (args // { type = nixvimTypes.attrs; });
      mkAttributeSet = default: description: mkAttributeSet' { inherit default description; };

      mkListOf' =
        { type, ... }@args: mkNullable' (args // { type = with nixvimTypes; listOf (maybeRaw type); });
      mkListOf =
        type: default: description:
        mkListOf' { inherit type default description; };

      mkAttrsOf' =
        { type, ... }@args: mkNullable' (args // { type = with nixvimTypes; attrsOf (maybeRaw type); });
      mkAttrsOf =
        type: default: description:
        mkAttrsOf' { inherit type default description; };

      mkEnum' =
        {
          values,
          default ? head values,
          ...
        }@args:
        # `values` is a list and `default` is one of the values (or null)
        assert isList values;
        assert default == null || elem default values;
        mkNullableWithRaw' (
          (filterAttrs (n: v: n != "values") args)
          // {
            # TODO we should remove this once `mkDesc` no longer has a special case
            default = if isString default then generators.toPretty { } default else default;
            type = types.enum values;
          }
        );
      mkEnum =
        values: default: description:
        mkEnum' { inherit values default description; };
      mkEnumFirstDefault = values: description: mkEnum' { inherit values description; };

      mkBorder' =
        {
          name,
          description ? "",
          ...
        }@args:
        mkNullableWithRaw' (
          (filterAttrs (n: v: n != "name") args)
          // {
            type = nixvimTypes.border;
            description = concatStringsSep "\n" (
              filter (s: s != "") [
                description
                "Defines the border to use for ${name}."
                "Accepts same border values as `nvim_open_win()`. See `:help nvim_open_win()` for more info."
              ]
            );
          }
        );
      mkBorder =
        default: name: description:
        mkBorder' { inherit default name description; };

      mkSeverity' =
        args:
        mkNullOrOption' (
          args
          // {
            type =
              with types;
              either ints.unsigned (enum [
                "error"
                "warn"
                "info"
                "hint"
              ]);
            apply = mapNullable (
              value: if isInt value then value else mkRaw "vim.diagnostic.severity.${strings.toUpper value}"
            );
          }
        );
      mkSeverity = default: description: mkSeverity' { inherit default description; };

      mkLogLevel' =
        args:
        mkNullOrOption' (
          args
          // {
            type = with nixvimTypes; either ints.unsigned logLevel;
            apply = mapNullable (
              value: if isInt value then value else mkRaw "vim.log.levels.${strings.toUpper value}"
            );
          }
        );
      mkLogLevel = default: description: mkLogLevel' { inherit default description; };

      mkHighlight' =
        {
          description ? "Highlight settings.",
          ...
        }@args:
        mkNullable' (
          args
          // {
            type = nixvimTypes.highlight;
            inherit description;
          }
        );
      # FIXME `name` argument is ignored
      # TODO deprecate in favor of `mkHighlight'`?
      mkHighlight =
        default: name: description:
        mkHighlight' (
          {
            inherit default;
          }
          // (optionalAttrs (description != null && description != "") { inherit description; })
        );
    };

  mkPackageOption =
    {
      name ? null, # Can be omitted if a custom description is given.
      description ? null,
      default, # `default` is not optional
      ...
    }@args:
    mkNullOrOption' (
      (filterAttrs (n: _: n != "name") args)
      // {
        type = types.package;
        description =
          if description == null then
            ''
              Which package to use for `${name}`.
              Set to `null` to disable its automatic installation.
            ''
          else
            description;
      }
    );

  mkPluginPackageOption =
    name: default:
    mkOption {
      type = types.package;
      inherit default;
      description = "Which package to use for the ${name} plugin.";
    };

  mkSettingsOption =
    {
      options ? { },
      description,
      example ? null,
    }:
    mkOption {
      type =
        with types;
        submodule {
          freeformType = attrsOf anything;
          inherit options;
        };
      default = { };
      inherit description;
      example =
        if example == null then
          {
            foo_bar = 42;
            hostname = "localhost:8080";
            callback.__raw = ''
              function()
                print('nixvim')
              end
            '';
          }
        else
          example;
    };
}
