require_relative "test_helper"

module TaxCalculator
  class VersionTest < Minitest::Test

    def test_version_constant_is_defined
      assert defined?(TaxCalculator::VERSION)
    end

    def test_version_is_string
      assert_kind_of String, TaxCalculator::VERSION
    end

    def test_version_matches_semver
      assert_match(/\A\d+\.\d+\.\d+\z/, TaxCalculator::VERSION)
    end

    def test_version_is_frozen
      assert TaxCalculator::VERSION.frozen?
    end
  end
end
