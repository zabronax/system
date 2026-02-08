{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.time = {
    timeAuthority = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "systemd-timesyncd" "ntp" "chrony" ]);
      default = null;
      description = "Time synchronization service to use. Applies on NixOS hosts (bare metal and WSL). Note: In WSL, Windows manages the hardware clock, but NTP sync can still be configured.";
      example = "systemd-timesyncd";
    };
  };

  config = lib.mkMerge [
    # Apply time zone configuration on NixOS (both bare metal and WSL)
    # All hosts can configure this, but only NixOS hosts will apply it
    # Note: time.timeZone is a built-in NixOS option, so we don't redefine it.
    # Hosts can set time.timeZone directly, and it will work on NixOS hosts.
    # We don't need to do anything special here since NixOS handles it natively.

    # Apply time authority configuration on NixOS (both bare metal and WSL)
    # All hosts can configure this, but only NixOS hosts will apply it
    # Note: In WSL, Windows manages hardware clock, but NTP sync can still be configured
    (lib.mkIf (config.time.timeAuthority != null && !pkgs.stdenv.isDarwin) {
      # Enable systemd-timesyncd if selected
      services.timesyncd.enable = config.time.timeAuthority == "systemd-timesyncd";
      
      # Enable NTP if selected
      services.ntp.enable = config.time.timeAuthority == "ntp";
      
      # Enable Chrony if selected
      services.chrony.enable = config.time.timeAuthority == "chrony";
    })
  ];
}
