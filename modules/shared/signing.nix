{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    signing = {
      # Signing service type - applications request signatures through the service
      # Key material never leaves the service/agent
      service = lib.mkOption {
        type = lib.types.enum [
          "gpg-agent"
          "pkcs11"
          "ssh-agent"
          "sigstore"
        ];
        description = "Signing service type. Applications request signatures through the service without accessing key material.";
        default = "gpg-agent";
      };

      # Key identifier for the signing service (not the key material itself)
      # Format depends on service type:
      # - gpg-agent: GPG key ID (e.g., "0xABCD1234" or fingerprint)
      # - pkcs11: PKCS#11 URI or token/key identifier
      # - ssh-agent: SSH key path or identifier
      # - sigstore: OIDC issuer or keyless signing configuration
      keyId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Key identifier for the signing service (not the key material). Applications request signatures through the service.";
        default = null;
        example = "0xABCD1234";
      };

      # Whether to sign by default for various operations
      signByDefault = lib.mkOption {
        type = lib.types.bool;
        description = "Enable signing by default for operations that support it.";
        default = false;
      };
    };
  };

  config = {
    # No default config - modules that use signing will implement their own
    # This just provides the options interface for service-based signing
    # Applications should request signatures through the configured service
  };
}
