# kizzycode/librechat

A Debian-based [LibreChat](https://github.com/danny-avila/LibreChat) container.

### Container users and mountpoints
Container users may interact with the external environment via mountpoints:
- `librechat`: A system user for the server; it has UID `10000`
  - Userdata should be mounted at `/home/librechat/userdata` as UID `10000`
