# App configuration

Verified against the repository on 2026-10-13.

`Shared.xcconfig` is committed and includes `Secrets.xcconfig` optionally.
Copy `Secrets.xcconfig.template` to `Secrets.xcconfig` and supply the API URL before connecting to the server. The default `.invalid` host supports a secret-free build and does not identify a live environment.

Use `https:/$()/host` in xcconfig files because `//` starts a comment.

```sh
cp UMCDesk/Secrets/Secrets.xcconfig.template UMCDesk/Secrets/Secrets.xcconfig
```

Both Debug and Release app configurations load `Shared.xcconfig`. Tuist exposes
`BASE_URL` through the app Info.plist, and `AppDependencies` validates it when
constructing the network environment. A syntactically valid `.invalid` URL
passes configuration validation but cannot connect to a product server.

`Secrets.xcconfig` is ignored. Keep credentials and local environment values out
of commits and release notes. Xcode Cloud's current post-clone script installs
tools and generates the workspace; it does not create this local file or map a
Cloud `BASE_URL` environment variable into it. Configure the intended API URL in
the build environment before packaging a server-connected distribution.

Auth screens currently simulate local UI state. Supplying a real URL does not
add login, email verification or registration API integration.
