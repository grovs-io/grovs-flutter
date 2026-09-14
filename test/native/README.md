# Native bridge regression checks

Run from the repository root:

```sh
python3 test/native/run.py
```

Use `ios` or `android` as the final argument to run one platform.

These checks run offline using platform stubs. Android compiles the complete
production plugin and uses a test main dispatcher. iOS compiles the production
event relay plus the plugin's registration, detach, and consent methods. The
runner replaces platform imports and exposes the private iOS consent method to
the tests. It leaves their behavior unchanged. Generated files go into a temporary
directory and are removed after the run.

Coverage includes buffer limits and ordering, consent withdrawal across engines,
queued callback rejection, engine replacement, error-only subscriptions, weak
ownership, late cancellation, activity rotation, and cancellation and reuse of
link generation.

These tests do not verify SDK API compatibility or device behavior. Run native
builds and device checks separately when the required SDK releases are available.

## Requirements

- Python 3, Xcode command line tools for iOS, and a JDK for Android.
- Android uses these Maven artifacts from the Gradle cache (`GRADLE_USER_HOME`,
  or `~/.gradle`). The versions match the tested standalone harness:
  - `org.jetbrains.kotlin:kotlin-compiler-embeddable:2.0.21`
  - `org.jetbrains.kotlin:kotlin-stdlib:2.0.21`
  - `org.jetbrains.kotlin:kotlin-script-runtime:2.0.21`
  - `org.jetbrains.kotlin:kotlin-reflect:1.6.10`
  - `org.jetbrains.intellij.deps:trove4j:1.0.20200330`
  - `org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.6.4` (compiler)
  - `org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.7.3` (tests)
  - `org.jetbrains.kotlinx:kotlinx-coroutines-test-jvm:1.7.3`
  - `org.jetbrains:annotations:13.0`

The runner reports a missing artifact rather than downloading it implicitly.
