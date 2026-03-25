# test/test_config.rb
require_relative 'test_helper'

class TestConfig < Minitest::Test
  def test_default_configuration
    config = TaxCalculator.config
    
    assert_equal 0.13, config.default_ndfl_rate
    assert_equal 0.20, config.default_vat_rate
    assert_equal 0.20, config.default_profit_rate
    assert_equal :rub, config.currency
    assert_equal :test, config.region
    assert_equal 2, config.rounding_precision
    assert_equal false, config.auto_apply_deductions
    assert_equal :info, config.log_level
    assert_equal false, config.cache_calculations
    assert_equal :test, config.validation_strictness
  end

  def test_configure_block
    TaxCalculator.configure do |config|
      config.default_ndfl_rate = 0.15
      config.region = :moscow
      config.rounding_precision = 0
    end

    assert_equal 0.15, TaxCalculator.config.default_ndfl_rate
    assert_equal :moscow, TaxCalculator.config.region
    assert_equal 0, TaxCalculator.config.rounding_precision
  end

  def test_reset_configuration
    TaxCalculator.configure do |config|
      config.default_ndfl_rate = 0.99
    end
    
    assert_equal 0.99, TaxCalculator.config.default_ndfl_rate
    
    TaxCalculator.reset_config!
    
    assert_equal 0.13, TaxCalculator.config.default_ndfl_rate
  end

  def test_multiple_configurations
    TaxCalculator.configure do |config|
      config.default_ndfl_rate = 0.13
      config.region = :spb
    end
    
    assert_equal 0.13, TaxCalculator.config.default_ndfl_rate
    assert_equal :spb, TaxCalculator.config.region
    
    TaxCalculator.configure do |config|
      config.default_ndfl_rate = 0.15
    end
    
    assert_equal 0.15, TaxCalculator.config.default_ndfl_rate
    assert_equal :spb, TaxCalculator.config.region 
  end
end