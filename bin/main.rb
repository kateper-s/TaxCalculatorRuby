#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/tax_calculator'
require 'date'
require 'json'

TaxCalculator.configure do |config|
  config.default_ndfl_rate = 0.13
  config.default_vat_rate = 0.20
  config.default_profit_rate = 0.20
  config.rounding_precision = 2
end

puts "=" * 60
puts "TAX CALCULATOR - ТЕСТИРОВАНИЕ"
puts "=" * 60
puts "\n📊 1. РАСЧЕТ НДФЛ (Personal Income Tax)"
puts "-" * 40

ndfl_result = TaxCalculator.calculate_ndfl(100_000)
puts "Доход: #{ndfl_result[:income]} руб."
puts "Ставка: #{ndfl_result[:tax_rate] * 100}%"
puts "Налог: #{ndfl_result[:tax_amount]} руб."
puts "Чистый доход: #{ndfl_result[:net_income]} руб."

ndfl_custom = TaxCalculator.calculate_ndfl(100_000, rate: 0.15)
puts "\nС пользовательской ставкой 15%:"
puts "Налог: #{ndfl_custom[:tax_amount]} руб."
puts "Чистый доход: #{ndfl_custom[:net_income]} руб."

# 2. Тестирование НДС
puts "\n📊 2. РАСЧЕТ НДС (VAT)"
puts "-" * 40

vat_result = TaxCalculator.calculate_vat(50_000)
puts "Сумма без НДС: #{vat_result[:amount]} руб."
puts "Ставка НДС: #{vat_result[:vat_rate] * 100}%"
puts "НДС: #{vat_result[:vat_amount]} руб."
puts "Сумма с НДС: #{vat_result[:total]} руб."

vat_custom = TaxCalculator.calculate_vat(50_000, rate: 0.10)
puts "\nС пользовательской ставкой 10%:"
puts "НДС: #{vat_custom[:vat_amount]} руб."
puts "Сумма с НДС: #{vat_custom[:total]} руб."

# 3. Тестирование налога на прибыль
puts "\n📊 3. РАСЧЕТ НАЛОГА НА ПРИБЫЛЬ (Profit Tax)"
puts "-" * 40

profit_result = TaxCalculator.calculate_profit_tax(500_000)
puts "Прибыль: #{profit_result[:profit]} руб."
puts "Ставка: #{profit_result[:tax_rate] * 100}%"
puts "Налог: #{profit_result[:tax_amount]} руб."
puts "Чистая прибыль: #{profit_result[:net_profit]} руб."
