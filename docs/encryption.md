# Vault encryption

## Current format

- Each private vault has a random 256-bit media key. Its six-digit PIN is fed
  through Argon2id (19 MiB, two passes, one lane, 16-byte random salt) to wrap
  that key with AES-256-GCM. The wrapped key, salt, and format version are
  encoded in the vault's `pinHash` field. PIN changes rewrap the media key.
- Each full file and thumbnail has a new 96-bit random GCM nonce and a 128-bit
  authentication tag. The media ID and file kind are authenticated as associated
  data. Changed, truncated, or swapped files fail authentication.
- The public gallery uses a random key held in platform secure storage. Its
  contents remain accessible without a PIN by design.
- Version 2 `.hpv` backups contain the wrapped media key, an authenticated
  manifest, and encrypted media. The manifest authenticates each blob's size
  and SHA-256 digest. Import verifies the entire archive before writing records.
  A backup restored with a PIN already used on the device merges into that
  vault and reencrypts media for their new IDs.
- Legacy CBC media are decrypted with the old PIN and upgraded on unlock or
  first read. Legacy version 1 backups are accepted and their contents are
  reencrypted into version 2 storage when imported. Export and PIN rotation
  fail if a legacy file cannot be migrated; they never silently omit it.
  Legacy CBC has no integrity check, so
  preexisting tampering cannot always be detected during migration.

## Limits and handling

- A six-digit PIN has only one million possibilities. Argon2id slows offline
  guessing, but a copied vault database or `.hpv` backup can still be attacked
  offline. A longer passphrase option is needed for stronger protection against
  a determined attacker, especially for shared backups.
- Hive metadata (vault names, original filenames, tags, MIME types, sizes, and
  timestamps) is not encrypted. The media bytes and thumbnails are encrypted.
- Viewing video and sharing media create plaintext temporary files. The app
  removes these when the viewer or private vault closes and on next launch;
  a crash can leave files until then. Explicit Save to Downloads creates a
  plaintext copy by user request.
- Android automatic cloud backup and device transfer of app data are disabled;
  use the encrypted `.hpv` export for recovery. iOS app backups and any external
  copy of the app container remain sensitive because of the six-digit PIN and
  unencrypted metadata.
- Encryption currently operates on whole media files in memory. Very large
  videos or archives can exceed device memory; a chunked authenticated format
  would address this before supporting arbitrarily large media.

Do not reuse a GCM nonce with the same key or write unauthenticated plaintext
after a decryption failure. Keep format changes versioned and add migration and
tampering tests before changing the binary layout.
