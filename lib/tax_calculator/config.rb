# lib/tax_calculator/config.rb
module TaxCalculator
  class Config
    attr_accessor :default_ndfl_rate, :default_vat_rate, :default_profit_rate,
                  :currency, :region, :rounding_precision, :auto_apply_deductions,
                  :log_level, :cache_calculations, :validation_strictness

    def initialize
      @default_ndfl_rate = 0.13
      @default_vat_rate = 0.20
      @default_profit_rate = 0.20
      @currency = :rub
      @region = :default
      @rounding_precision = 2
      @auto_apply_deductions = true
      @log_level = :info
      @cache_calculations = false
      @validation_strictness = :normal
    end
  end
end