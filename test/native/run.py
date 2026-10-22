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
IOS = ROOT / "ios/grovs_flutter_plugin/Sources/grovs_flutter_plugin"
ANDROID = ROOT / "android/src/main/kotlin/io/grovs/wrapper"
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


IOS_TEST_PROGRAMS = ["ios_tests.swift", "ios_launch_tests.swift", "ios_push_tests.swift"]


def swift(out):
    relay = (IOS / "GrovsEventRelay.swift").read_text()
    plugin = (IOS / "GrovsPlugin.swift").read_text()
    scene = (IOS / "GrovsPlugin+Scene.swift").read_text()
    push = (IOS / "GrovsPlugin+Push.swift").read_text()
    # Include the real registration, engine cleanup, lifecycle, configuration, link delivery, push and consent methods.
    bridge = plugin[:plugin.index("    // Hook into didFinishLaunchingWithOptions")]
    for marker in (
        "    public func application(_ application: UIApplication, didFinishLaunchingWithOptions",
        "    public func application(_ application: UIApplication, continue",
        "    public func application(_ app: UIApplication, open",
        "    static func configureFromInfoPlist",
        "    static func deliver",
        "    static func handleUrl(arguments",
        "    static func linkDetails(arguments",
        "    static func isGrovsNotification(arguments",
        "    static func handleNotificationOpen(arguments",
        "    private func setSDKEnabled",
    ):
        bridge += function(plugin, marker) + "\n"
    bridge += "}\n" + scene + push
    bridge = bridge.replace("public ", "").replace("private func setSDKEnabled", "func setSDKEnabled")
    bridge = bridge.replace("[UIApplication.OpenURLOptionsKey : Any]", "[String: Any]")
    bridge = bridge.replace("Bundle.main.infoDictionary", "testInfoDictionary")
    # Each test file is its own program, so static plugin state starts fresh in each.
    for tests in IOS_TEST_PROGRAMS:
        source = (HERE / "ios_stubs.swift").read_text() + relay + bridge + (HERE / tests).read_text()
        source = re.sub(r"^import (Flutter|Grovs|UIKit|UserNotifications)\n", "", source, flags=re.M)
        program = out / Path(tests).stem
        program.mkdir()
        (program / "main.swift").write_text(source)
        run("xcrun", "swift", "-swift-version", "5", "-module-cache-path", out / "cache", program / "main.swift")


def jar(artifact, version):
    paths = [p for p in CACHE.glob(f"*/{artifact}/{version}/*/*.jar") if not p.name.endswith(("-sources.jar", "-javadoc.jar"))]
    if not paths:
        raise SystemExit(f"Missing cached {artifact}:{version}. See test/native/README.md.")
    return paths[0]


def kotlin(out):
    # Compile the complete bridge; only platform imports are replaced by stubs.
    sources = []
    for path in sorted(ANDROID.glob("*.kt")):
        source = re.sub(r"^(package io\..*|import (android|androidx|io|com\.google)\..*)\n", "", path.read_text(), flags=re.M)
        (out / path.name).write_text(source)
        sources.append(out / path.name)
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
        *sources, out / "Build.kt", HERE / "android_stubs.kt", HERE / "android_tests.kt")
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
