# Security audit findings

Key upstream risks were forced deployment, shell-startup downloads, unchecked installers, mutable `latest` downloads, and privileged repository changes. The new design rejects conflicts, has no startup network activity, checks executable hashes, pins normal tools, and confines the two `latest` exceptions to named npm modules.
