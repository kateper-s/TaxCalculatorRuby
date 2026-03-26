require_relative "test_helper"

module TaxCalculator
  class ConfigTest < Minitest::Test

    def setup
      @config = Config.new
    end

    def test_default_ndfl_rate
      assert_equal 0.13, @config.default_ndfl_rate
    end

    def test_default_vat_rate
      assert_equal 0.20, @config.default_vat_rate
    end

    def test_default_profit_rate
      assert_equal 0.20, @config.default_profit_rate
    end

    def test_default_currency
      assert_equal :rub, @config.currency
    end

    def test_default_region
      assert_equal :default, @config.region
    end

    def test_default_rounding_precision
      assert_equal 2, @config.rounding_precision
    end

    def test_auto_apply_deductions_is_true_by_default
      assert @config.auto_apply_deductions
    end

    def test_default_log_level
      assert_equal :info, @config.log_level
    end

    def test_cache_calculations_is_false_by_default
      refute @config.cache_calculations
    end

    def test_default_validation_strictness
      assert_equal :normal, @config.validation_strictness
    end


    def test_ndfl_rate_can_be_changed
      @config.default_ndfl_rate = 0.15
      assert_equal 0.15, @config.default_ndfl_rate
    end

    def test_currency_can_be_changed
      @config.currency = :usd
      assert_equal :usd, @config.currency
    end

    def test_rounding_precision_can_be_changed
      @config.rounding_precision = 4
      assert_equal 4, @config.rounding_precision
    end

    def test_two_instances_are_independent
      other = Config.new
      @config.default_ndfl_rate = 0.20
      assert_equal 0.13, other.default_ndfl_rate
    end
  end
end
