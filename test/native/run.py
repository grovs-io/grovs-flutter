#!/usr/bin/env python3
"""Run bridge behavior checks with platform stubs, without published native SDKs."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
CACHE = Path(os.environ.get("GRADLE_USER_HOME", Path.home() / ".gradle")) / "caches/modules-2/files-2.1"


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def function(source, marker):
    start = source.index(marker)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


def swift(out):
    relay = (ROOT / "ios/Classes/GrovsEventRelay.swift").read_text()
    plugin = (ROOT / "ios/Classes/GrovsPlugin.swift").read_text()
    # Include the real registration, engine cleanup, and consent methods.
    bridge = plugin[:plugin.index("    // Hook into didFinishLaunchingWithOptions")]
    bridge += function(plugin, "    private func setSDKEnabled") + "\n}\n"
    bridge = bridge.replace("public ", "").replace("private func setSDKEnabled", "func setSDKEnabled")
    source = (HERE / "ios_stubs.swift").read_text() + relay + bridge + (HERE / "ios_tests.swift").read_text()
    source = re.sub(r"^import (Flutter|Grovs|UIKit)\n", "", source, flags=re.M)
    (out / "main.swift").write_text(source)
    run("xcrun", "swift", "-swift-version", "5", "-module-cache-path", out / "cache", out / "main.swift")


def jar(artifact, version):
    paths = [p for p in CACHE.glob(f"*/{artifact}/{version}/*/*.jar") if not p.name.endswith(("-sources.jar", "-javadoc.jar"))]
    if not paths:
        raise SystemExit(f"Missing cached {artifact}:{version}. See test/native/README.md.")
    return paths[0]


def kotlin(out):
    source = (ROOT / "android/src/main/kotlin/io/grovs/wrapper/GrovsPlugin.kt").read_text()
    # Compile the complete bridge; only platform imports are replaced by stubs.
    source = re.sub(r"^(package io\..*|import (android|io)\..*)\n", "", source, flags=re.M)
    (out / "GrovsPlugin.kt").write_text(source)
    (out / "Build.kt").write_text('package android.os\nobject Build { object VERSION { const val RELEASE = "test" } }\n')
    compiler = [jar(a, v) for a, v in [
        ("kotlin-compiler-embeddable", "2.0.21"), ("kotlin-stdlib", "2.0.21"),
        ("kotlin-script-runtime", "2.0.21"), ("kotlin-reflect", "1.6.10"),
        ("trove4j", "1.0.20200330"), ("kotlinx-coroutines-core-jvm", "1.6.4"), ("annotations", "13.0"),
    ]]
    libraries = [jar(a, v) for a, v in [
        ("kotlin-stdlib", "2.0.21"), ("kotlinx-coroutines-core-jvm", "1.7.3"),
        ("kotlinx-coroutines-test-jvm", "1.7.3"), ("annotations", "13.0"),
    ]]
    classpath = os.pathsep.join(map(str, libraries))
    run("java", "-cp", os.pathsep.join(map(str, compiler)), "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
        "-nowarn", "-no-stdlib", "-no-reflect", "-classpath", classpath, "-d", out / "classes",
        out / "GrovsPlugin.kt", out / "Build.kt", HERE / "android_stubs.kt", HERE / "android_tests.kt")
    run("java", "-cp", str(out / "classes") + os.pathsep + classpath, "Android_testsKt")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("platform", choices=["ios", "android", "all"], nargs="?", default="all")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="grovs-native-tests-") as directory:
        output = Path(directory)
        if args.platform in ("ios", "all"):
            swift(output)
        if args.platform in ("android", "all"):
            kotlin(output)
