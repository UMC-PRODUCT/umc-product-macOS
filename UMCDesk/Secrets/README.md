# App configuration

`Shared.xcconfig` is committed and includes `Secrets.xcconfig` optionally.
Copy `Secrets.xcconfig.template` to `Secrets.xcconfig` and supply the API URL before connecting to the server. The default `.invalid` host supports a secret-free build and does not identify a live environment.

Use `https:/$()/host` in xcconfig files because `//` starts a comment.
