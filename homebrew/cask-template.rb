# Homebrew Cask definition for Pod Block
# Copy this to your homebrew-pod-block tap repo as Casks/pod-block.rb
# and fill in the TODOs before publishing.

cask "pod-block" do
  version "TODO"  # e.g. "1.0.0"
  sha256 "TODO"   # output of: shasum -a 256 PodBlock-<version>.dmg

  url "https://github.com/kokorro-labs/pod-block/releases/download/v#{version}/PodBlock-#{version}.dmg"
  name "Pod Block"
  desc "Automatically switches default audio input away from AirPods to your preferred microphone"
  homepage "https://github.com/kokorro-labs/pod-block"

  depends_on macos: ">= :ventura"

  app "Pod Block.app"

  zap trash: [
    "~/Library/Preferences/com.kokorro-labs.pod-block.plist",
    "~/Library/LaunchAgents/com.kokorro-labs.pod-block.plist",
  ]
end
