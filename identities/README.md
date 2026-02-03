# Identities

Identities are first-class primitives in this system configuration. They represent abstract identity information that can be shared across multiple hosts.

## Design Philosophy

Identities are **atoms** - abstract primitives that are not bound to any specific host. Each host translates these abstract identities into concrete user configurations with host-specific details (like `homePath` which differs between Linux `/home/` and macOS `/Users/`).

## Schema Structure

The identity schema follows a certificate-like structure, inspired by OIDC and similar standards, but simplified for practical system configuration needs.

### Core Fields

- **`commonName`**: Primary machine-readable identifier (similar to OIDC's `sub` or `preferred_username`)
- **`displayName`**: Human-readable identifier (similar to OIDC's `name`)
- **`email`**: Contact email address

### Cryptographic Fields

- **`publicKey`**: Public key for SSH/GPG/etc.
- **`fingerprint`**: Key fingerprint for verification

These are kept minimal for current needs. Future extensions (key rotation, trust authorities, etc.) are documented in commented sections.

## Future Extensibility

The schema includes commented-out sections for future features:

- **Trust/Verification**: eIDAS-style trust authority integration (when budget/need allows)
- **Linked Identities**: Connections to identities from other authorities (OIDC, etc.)
- **DID (Decentralized Identifiers)**: Self-sovereign identity standards like FolkeID (Norway) - could provide decentralized identity verification without a central authority
- **Aliases**: Alternative contact details and social media handles

## Usage

Hosts import identities and translate them to concrete user configurations:

```nix
# In host configuration
privateIdentity = import ../../identities/private;

userConfig = {
  user = privateIdentity.commonName;      # System username
  gitName = privateIdentity.displayName;  # Git name
  gitEmail = privateIdentity.email;       # Git email
  homePath = "/home/${privateIdentity.commonName}";  # Host-specific
};
```

## Design Decisions

### Why Certificate-like?

- Aligns with established identity standards (OIDC, X.509)
- Clear separation between machine-readable (`commonName`) and human-readable (`displayName`)
- Familiar terminology for developers

### Why Not Full OIDC?

- OIDC includes many fields we don't need (given_name, family_name, picture, etc.)
- This is a system configuration, not a passport
- Simpler schema is easier to maintain and reason about

### Why Not Subject Identifiers?

- `sub` (subject) implies an authority that issued the identifier
- We're self-sovereign identities, not relying on external authorities (yet)
- `commonName` is more appropriate for our use case
- Future: DIDs (like FolkeID) could provide decentralized identity without central authority dependency

### Cryptographic Details

Kept minimal for now:
- `publicKey` and `fingerprint` cover current needs (SSH, GPG)
- Future trust authority integration (eIDAS-style) is documented but not implemented
- Key rotation and advanced features can be added when needed
