class OhMyAgent < Formula
  desc "Portable multi-agent harness for .agents-based skills and workflows"
  homepage "https://firstfluke.com/oh-my-agent/"
  url "https://registry.npmjs.org/oh-my-agent/-/oh-my-agent-12.3.1.tgz"
  sha256 "a1ecd6cca0fb04204f9be450550403576e4972334a37f4323b6a61f77d69dfce"
  license "MIT"

  bottle do
    sha256 cellar: :any, arm64_tahoe:   "efd9b413b79305556d5394744b08c9944d906d3c566588e78ed6068d0196d2e0"
    sha256 cellar: :any, arm64_sequoia: "25c64e4bdcdad33bf903a148c9b142e3f85335ef33e14f35da5bb8074a75b134"
    sha256 cellar: :any, arm64_sonoma:  "8dfe0b16b12b38358679d9af168f3c444f9c968c11d2262d3bb39a2a22ffb69a"
    sha256 cellar: :any, sonoma:        "a37db2ffe950331496c14558c7acb62210103aed5c007728bf131967c76d0ce2"
    sha256 cellar: :any, arm64_linux:   "959b1461a4037666664cf829ad7858b788e7404cd2c5b2c237f4acdc208081b8"
    sha256 cellar: :any, x86_64_linux:  "7d2274555f8a09ca6af043feb33fd2c01daef398d15d6e4cacb597ab4cecff6a"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args

    node_modules = libexec/"lib/node_modules/oh-my-agent/node_modules"
    # Remove incompatible pre-built `bare-fs`/`bare-os`/`bare-path`/`bare-url` binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob("{bare-fs,bare-os,bare-path,bare-url}/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }

    rm_r(node_modules.glob("better-sqlite3/prebuilds/*"))
    cd(node_modules/"better-sqlite3") { system "npm", "run", "build-release" }

    bin.install_symlink Dir[libexec/"bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/oh-my-agent --version")

    output = JSON.parse(shell_output("#{bin}/oh-my-agent memory:init --json"))
    assert_empty output["updated"]
    assert_path_exists testpath/".agents/state/memories/orchestrator-session.md"
    assert_path_exists testpath/".agents/state/memories/task-board.md"
  end
end
