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
    cd "dogsdogsdogs" do
      system "cargo", "build", "--release", "--lib"
      mkdir_p lib
      Dir["target/release/libdifferential_dogs3.{dylib,so,a}"].each do |f|
        cp f, lib if File.exist?(f)
      end
    end
  end

  test do
    assert_path_exists lib/"libdifferential_dogs3.a"
  end
end
