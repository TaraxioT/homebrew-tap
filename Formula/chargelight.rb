class Chargelight < Formula
  desc "Program the LED on your MagSafe charger from a shell, a script or an agent"
  homepage "https://github.com/TaraxioT/chargelight"
  url "https://github.com/TaraxioT/chargelight/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "5662bd3eea7e86573cfd9d4fe5c412c8cc0bed8088029cec37faeeb3d0059c62"
  license "MIT"
  head "https://github.com/TaraxioT/chargelight.git", branch: "main"

  depends_on arch: :arm64
  depends_on :macos

  uses_from_macos "swift" => :build

  def install
    args = ["--disable-sandbox", "--configuration", "release"]
    system "swift", "build", *args
    products = Pathname.new(Utils.safe_popen_read("swift", "build", *args, "--show-bin-path").strip)

    bin.install products/"chargelight"
    # Not on PATH: `sudo chargelight setup` copies it to a root-owned location.
    libexec.install products/"chargelight-helper"

    generate_completions_from_executable(bin/"chargelight", "completions")
  end

  def caveats
    <<~EOS
      Changing the LED needs root. Install the passwordless helper once:
        sudo chargelight setup

      Then try it (with the MagSafe charger plugged in):
        chargelight play
        chargelight amber
        chargelight flash green
        chargelight run -- sleep 5
        chargelight system

      For Claude Code, add the plugin from inside a session:
        /plugin marketplace add TaraxioT/chargelight
        /plugin install chargelight@chargelight
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chargelight --version")

    # Simulated LED: no hardware and no root.
    ENV["CHARGELIGHT_HOME"] = (testpath/"state").to_s
    ENV["CHARGELIGHT_BACKEND"] = "file"
    ENV["CHARGELIGHT_NO_WATCHER"] = "1"
    system bin/"chargelight", "claim", "test", "heartbeat", "--priority", "40"
    assert_equal "amber", shell_output("#{bin}/chargelight get").strip
    assert_match "heartbeat", shell_output("#{bin}/chargelight status")
    # `run` passes the command's exit status through.
    shell_output("#{bin}/chargelight run --keep 0 -- sh -c 'exit 3'", 3)
    assert_match "0.1.0", shell_output("#{libexec}/chargelight-helper --version")
  end
end
