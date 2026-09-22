# network

This virtual module represents the centralized network and mirror policy implemented by `lib/network.sh`.

It intentionally has no lifecycle script or deployed configuration. Other modules may depend on it to make network policy ordering explicit without duplicating proxy or mirror logic.
