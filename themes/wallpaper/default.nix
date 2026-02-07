{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Platform-agnostic functions for wallpaper processing pipeline

  # Extract the store path from a source (derivation or path)
  sourceToPath = source: if lib.isDerivation source then source.outPath else source;

  # Project a source repository (derivation or path) into a set of absolute filepaths
  projectSourceToFilepaths = source: lib.filesystem.listFilesRecursive (sourceToPath source);

  # Fold a set of absolute filepaths into a Nix derivation containing the list
  foldFilepathsToDerivation =
    filepaths: name: pkgs.writeText name (lib.concatStringsSep "\n" (map toString filepaths));
in
{
  options = {
    wallpaper = {
      enable = lib.mkEnableOption {
        description = "Enable desktop wallpaper configuration.";
        default = false;
      };

      source = lib.mkOption {
        type = lib.types.path;
        description = "Flake input source containing wallpapers (e.g., inputs.walls).";
        example = "inputs.walls";
      };

      # Static wallpaper: specify a concrete path relative to source
      # Example: wallpaper.path = "aerial/wallpaper.jpg";
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Path to image file relative to the source root (for static wallpaper mode).";
        default = null;
        example = "gruvbox/a_landscape_with_mountains_and_trees.jpg";
      };

      # Dynamic wallpaper: random selection with interval and filter
      dynamic = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              interval = lib.mkOption {
                type = lib.types.enum [
                  "hourly"
                  "daily"
                  "weekly"
                ];
                description = "Interval for random wallpaper updates.";
                example = "hourly";
              };

              filter = lib.mkOption {
                type = lib.types.functionTo lib.types.bool;
                description = "Nix predicate function for filtering wallpapers. Takes a wallpaper path (relative to source) and returns true if it should be included.";
                default = _: true;
                example = "path: builtins.match \"^apocalypse/.*\" path != null";
              };
            };
          }
        );
        description = "Dynamic wallpaper selection configuration.";
        default = null;
      };

      # Supported image file extensions for wallpapers
      supportedExtensions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of supported image file extensions (with leading dot).";
        default = [
          ".jpg"
          ".jpeg"
          ".png"
          ".gif"
          ".heic"
          ".webp"
        ];
      };
    };
  };

  config = lib.mkIf config.wallpaper.enable (
    lib.mkMerge [
      # macOS-specific wallpaper configuration
      (lib.mkIf pkgs.stdenv.isDarwin (
        let
          # Load unified wallpaper script
          wallpaperScript = pkgs.writeShellScriptBin "darwin-set-wallpaper" (
            builtins.readFile ./darwin-set-wallpaper.sh
          );

          # Static wallpaper mode
          staticConfig = lib.mkIf (config.wallpaper.path != null) {
            home-manager.users.${config.user} = {
              launchd.agents.setWallpaper = {
                enable = true;
                config = {
                  Label = "com.system.wallpaper";
                  ProgramArguments = [
                    "${wallpaperScript}/bin/darwin-set-wallpaper"
                    "exact"
                    "${sourceToPath config.wallpaper.source}/${config.wallpaper.path}"
                  ];
                  RunAtLoad = true;
                  KeepAlive = false;
                };
              };
            };
          };

          # Dynamic wallpaper mode (random selection with filter)
          dynamicConfig = lib.mkIf (config.wallpaper.dynamic != null) (
            let
              # Derivation file list from source
              allFilepaths = projectSourceToFilepaths config.wallpaper.source;

              # Bind platform filter to supported formats
              darwinSupportedWallpaperFormats = config.wallpaper.supportedExtensions;
              formatFilter =
                absPath: lib.any (ext: lib.hasSuffix ext (toString absPath)) darwinSupportedWallpaperFormats;

              # Bind user filter to derivation directory
              sourcePathStr = toString (sourceToPath config.wallpaper.source);
              userFilter =
                absPath:
                config.wallpaper.dynamic.filter (lib.removePrefix (sourcePathStr + "/") (toString absPath));

              # Compose filters together
              filteredFilepaths = lib.filter userFilter (lib.filter formatFilter allFilepaths);

              # Fold to derivation and use in launchd agent
              wallpaperListFile = foldFilepathsToDerivation filteredFilepaths "wallpaper-list.txt";

              # Map interval to launchd interval
              intervalSeconds =
                {
                  hourly = 3600;
                  daily = 86400;
                  weekly = 604800;
                }
                .${config.wallpaper.dynamic.interval};
            in
            {
              home-manager.users.${config.user} = {
                launchd.agents.setRandomWallpaper = {
                  enable = true;
                  config = {
                    Label = "com.system.random-wallpaper";
                    ProgramArguments = [
                      "${wallpaperScript}/bin/darwin-set-wallpaper"
                      "random"
                      (toString wallpaperListFile)
                    ];
                    StartInterval = intervalSeconds;
                    RunAtLoad = true;
                    KeepAlive = false;
                  };
                };
              };
            }
          );
        in
        lib.mkMerge [
          staticConfig
          dynamicConfig
        ]
      ))

      # Linux-specific wallpaper configuration
      (lib.mkIf pkgs.stdenv.isLinux {
        # TODO: Add Linux wallpaper support when needed
        # This could use feh, nitrogen, or other tools depending on the desktop environment
      })
    ]
  );
}
