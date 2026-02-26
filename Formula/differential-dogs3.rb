class DifferentialDogs3 < Formula
  desc "C library for the differential-dogs3 join operators"
  homepage "https://github.com/TimelyDataflow/differential-dataflow"
  url "https://github.com/TimelyDataflow/differential-dataflow/archive/refs/tags/differential-dogs3-v0.19.1.tar.gz"
  sha256 "f8ded99eada449a1de19773597b9bd4fdf0995fb3185b293c80b9b6396b686ba"
  license "MIT"

  livecheck do
    url :stable
    regex(/differential-dogs3-v(\d+(?:\.\d+)+)/i)
  end

  depends_on "rust" => :build

  def install
    mkdir_p lib

    # Build all libraries
    system "cargo", "build", "--release", "--lib"
    system "cargo", "build", "--release", "--lib", "-p", "differential-dataflow"

    # Copy libraries to lib directory
    Dir["target/release/libdifferential_dogs3.{dylib,so,a,rlib}"].each do |f|
      cp f, lib
    end
    cp "target/release/libdifferential_dataflow.rlib", lib if
      File.exist?("target/release/libdifferential_dataflow.rlib")

    # Build and install binaries from server directory
    cd "server" do
      system "cargo", "install", "--bin", "dd_server", "--features", "timely/getopts",
             *std_cargo_args

      # Build plugin libraries
      %w[degr_dist neighborhood random_graph reachability].each do |plugin|
        cd "dataflows/#{plugin}" do
          system "cargo", "build", "--release", "--lib"
        end
      end
    end

    # Copy plugin libraries from workspace target
    %w[degr_dist neighborhood random_graph reachability].each do |plugin|
      cp "target/release/lib#{plugin}.dylib", lib if
        File.exist?("target/release/lib#{plugin}.dylib")
    end

    # Install doop binary from doop directory
    cd "doop" do
      system "cargo", "install", "--bin", "doop", "--features", "timely/getopts",
             *std_cargo_args
    end
  end

  test do
    assert_path_exists lib/"libdifferential_dogs3.a"
  end
end
