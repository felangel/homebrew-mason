require "yaml"

class Mason < Formula
  desc "A template generator which helps teams generate files quickly and consistently."
  homepage "https://github.com/felangel/mason"
  url "https://github.com/felangel/mason/archive/refs/tags/mason_cli-v0.1.3.tar.gz"
  sha256 "a21a2de3bb340d9811d5fe32608a031a65dcd0499b4b9688784a275a48d471ba"
  license "MIT"

  # Determine architecture and set the Dart SDK resource accordingly
  dart_sdk_version = "3.7.0"
  dart_sdk_url, dart_sdk_sha = if OS.mac? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-macos-x64-release.zip",
     "d601c9da420552dc6deba1992d07aad9637b970077d58c5cda895baebc83d7f5"]
  elsif OS.mac? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-macos-arm64-release.zip",
     "9bfd7c74ebc5f30b5832dfcf4f47e5a3260f2e9b98743506c67ad02b3b6964bb"]
  elsif OS.linux? && Hardware::CPU.intel?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-linux-x64-release.zip",
     "7c849abc0d06a130d26d71490d5f2b4b2fe1ca477b1a9cee6b6d870e6f9d626f"]
  elsif OS.linux? && Hardware::CPU.arm?
    ["https://storage.googleapis.com/dart-archive/channels/stable/release/#{dart_sdk_version}/sdk/dartsdk-linux-arm64-release.zip",
     "367b5a6f1364a1697dc597775e5cd7333c332363902683a0970158cbb978b80d"]
  end

  resource "dart-sdk" do
    url dart_sdk_url
    sha256 dart_sdk_sha
  end

  def install
    # Resource installation for Dart SDK
    resource("dart-sdk").stage do
      libexec.install Dir["*"] # Assumes Dart SDK zip layout matches what's expected
    end
    
    # Tell the pub server where these installations are coming from.
    ENV["PUB_ENVIRONMENT"] = "homebrew:mason_cli"

    # Adjust paths to use the vendored Dart SDK
    dart = libexec/"bin/dart"

    # Change directories into the mason_cli package directory.
    Dir.chdir('packages/mason_cli')

    system dart, "pub", "get"
  
    if Hardware::CPU.is_64_bit?
      _install_native_executable(dart)
    else
      _install_script_snapshot(dart)
    end

    chmod 0555, "#{bin}/mason"
  end

  private

  def _version
    @_version ||= YAML.safe_load(File.read("pubspec.yaml"))["version"]
  end

  def _install_native_executable(dart)
    system dart, "compile", "exe", "-Dversion=#{_version}",
           "bin/mason.dart", "-o", "mason"
    bin.install "mason"
  end

  def _install_script_snapshot
    system _dart/"dart", "compile", "jit-snapshot",
           "-Dversion=#{_version}",
           "-o", "mason.dart.app.snapshot",
           "bin/mason.dart"
    lib.install "mason.dart.app.snapshot"
    
    cp dart, lib

    (bin/"mason").write <<~SH
      #!/bin/sh
      exec "#{lib}/dart" "#{lib}/mason.dart.app.snapshot" "$@"
    SH
  end
end
