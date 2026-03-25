# lib/tax_calculator.rb
require_relative 'tax_calculator/version'
require_relative 'tax_calculator/config'
require_relative 'tax_calculator/personal_income_tax'
require_relative 'tax_calculator/corporate_tax'  
require_relative 'tax_calculator/vat'
require_relative 'tax_calculator/tax_deductions'
require_relative 'tax_calculator/tax_benefits'
require_relative 'tax_calculator/tax_reports'

module TaxCalculator
  class Error < StandardError; end
  
  def self.configuration
    @configuration = Config.new
  end
  
  def self.configure
    yield(configuration) if block_given?
    configuration
  end
  
  def self.reset_config!
    @configuration = Config.new
  end
  
  def self.default_ndfl_rate
    configuration.default_ndfl_rate
  end
  
  def self.default_vat_rate
    configuration.default_vat_rate
  end
  
  def self.default_profit_rate
    configuration.default_profit_rate
  end
  
  def self.calculate_ndfl(income, **options)
    rate = options[:rate]  configuration.default_ndfl_rate
    tax = income * rate
    
    {
      income: income,
      tax_rate: rate,
      tax_amount: tax.round(configuration.rounding_precision),
      net_income: (income - tax).round(configuration.rounding_precision)
    }
  end
  
  def self.calculate_vat(amount, **options)
    rate = options[:rate]  configuration.default_vat_rate
    vat = amount * rate
    
    {
      amount: amount,
      vat_rate: rate,
      vat_amount: vat.round(configuration.rounding_precision),
      total: (amount + vat).round(configuration.rounding_precision)
    }
  end
  
  def self.calculate_profit_tax(profit, **options)
    rate = options[:rate]  configuration.default_profit_rate
    tax = profit * rate
    
    {
      profit: profit,
      tax_rate: rate,
      tax_amount: tax.round(configuration.rounding_precision),
      net_profit: (profit - tax).round(configuration.rounding_precision)
    }
  end
end