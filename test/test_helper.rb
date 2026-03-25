require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'json'
require 'csv'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'test/'
    add_group 'Core', 'lib/tax_calculator'
    add_group 'Utilities', 'lib/tax_calculator/utils'
  end
end

require_relative '../lib/tax_calculator'

class Minitest::Test
  def setup
    if TaxCalculator.respond_to?(:reset_config!)
      TaxCalculator.reset_config!
    end
  
    TaxCalculator.configure do |config|
      config.default_ndfl_rate = 0.13
      config.default_vat_rate = 0.20
      config.default_profit_rate = 0.20
      config.region = :test
      config.currency = :rub
      config.rounding_precision = 2
      config.auto_apply_deductions = false
      config.validation_strictness = :test
    end
  end

  def teardown
  end

  def assert_tax_calculation(expected_tax, income, options = {})
    result = TaxCalculator.calculate_ndfl(income, **options)
    assert_equal expected_tax, result[:tax_amount]
  end

  def assert_within_tolerance(expected, actual, tolerance = 0.01)
    assert_in_delta expected, actual, tolerance
  end

  def fixture_file(filename)
    File.expand_path("fixtures/#{filename}", __dir__)
  end
  
  def create_temp_csv(data)
    Tempfile.create(['test', '.csv']) do |file|
      CSV.open(file.path, 'w') do |csv|
        data.each { |row| csv << row }
      end
      yield file.path
    end
  end
end