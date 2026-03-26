# frozen_string_literal: true

require 'bigdecimal'

module TaxCalculator
  class VAT
    VAT_RATES = {
      standard: BigDecimal('0.20'),
      reduced: BigDecimal('0.10'),
      super_reduced: BigDecimal('0.00'),
      estimated: BigDecimal('0.20') / BigDecimal('1.20'),
      export: BigDecimal('0.00'),
      exempt: nil
    }.freeze

    def initialize(company_type: :llc, vat_registered: true)
      @company_type = company_type
      @vat_registered = vat_registered
      @invoices = []
      @vat_period = :quarter
      @vat_declarations = []
    end

    def add_invoice(number:, date:, amount:, vat_rate:, counterparty:, type: :sale)
      # Преобразуем amount и vat_rate в BigDecimal
      amount = BigDecimal(amount.to_s)
      vat_rate = vat_rate_to_bigdecimal(vat_rate)
      vat_amount = calculate_vat(amount, vat_rate)

      @invoices << {
        number: number,
        date: date,
        amount: amount,
        vat_rate: vat_rate,
        vat_amount: vat_amount,
        total_with_vat: amount + vat_amount,
        counterparty: counterparty,
        type: type,
        quarter: quarter_of_date(date),
        is_valid: validate_invoice(number, date, counterparty)
      }
    end

    def calculate_vat_payable(quarter: nil)
      period_invoices = quarter ? invoices_by_quarter(quarter) : @invoices

      vat_outgoing = sum_vat_by_type(period_invoices, :sale)
      vat_incoming = sum_vat_by_type(period_invoices, :purchase)

      vat_payable = vat_outgoing - vat_incoming

      vat_recovered = calculate_recovered_vat(period_invoices)

      {
        period: quarter || 'all',
        vat_outgoing: vat_outgoing,
        vat_incoming: vat_incoming,
        vat_recovered: vat_recovered,
        vat_payable: vat_payable + vat_recovered,
        transactions_count: period_invoices.size,
        by_rate: breakdown_by_rate(period_invoices)
      }
    end

    def purchase_ledger(*)
      purchases = @invoices.select { |i| i[:type] == :purchase }

      {
        total_purchases: purchases.sum { |i| i[:amount] },
        total_vat: purchases.sum { |i| i[:vat_amount] },
        by_counterparty: group_by_counterparty(purchases),
        by_rate: breakdown_by_rate(purchases),
        deductions_eligible: calculate_eligible_deductions(purchases)
      }
    end

    def sales_ledger(*)
      sales = @invoices.select { |i| i[:type] == :sale }

      {
        total_sales: sales.sum { |i| i[:amount] },
        total_vat: sales.sum { |i| i[:vat_amount] },
        by_counterparty: group_by_counterparty(sales),
        export_sales: sales.select { |i| vat_rate_equal?(i[:vat_rate], VAT_RATES[:export]) },
        taxable_at_standard: sales.select { |i| vat_rate_equal?(i[:vat_rate], VAT_RATES[:standard]) }
      }
    end

    def proportional_deduction_check
      total_revenue = @invoices.select { |i| i[:type] == :sale }.sum { |i| i[:amount] }
      taxable_revenue = @invoices.select { |i| i[:type] == :sale && !i[:vat_rate].nil? && i[:vat_rate] > BigDecimal('0') }.sum { |i| i[:amount] }

      return unless total_revenue.positive?

      proportion = taxable_revenue / total_revenue

      {
        proportion: proportion,
        can_deduct_full: proportion > BigDecimal('0.95'),
        must_proportion: proportion < BigDecimal('0.95') && proportion > BigDecimal('0.05'),
        adjustment_needed: proportion < BigDecimal('0.05') ? 'No deduction allowed' : 'Proportional deduction',
        adjustment_calculation: calculate_proportional_adjustment(proportion)
      }
    end

    def calculate_recovery(asset_type:, years_used:, total_vat:)
      total_vat = BigDecimal(total_vat.to_s)

      case asset_type
      when :real_estate
        remaining_years = 10 - years_used
        annual_recovery = total_vat / 10
        {
          total_recovery: annual_recovery * remaining_years,
          annual: annual_recovery,
          schedule: (1..remaining_years).map do |year|
            { year: year, amount: annual_recovery }
          end
        }
      when :fixed_asset
        remaining_years = 5 - years_used
        annual_recovery = total_vat / 5
        {
          total_recovery: annual_recovery * remaining_years,
          annual: annual_recovery
        }
      end
    end

    def generate_vat_declaration(quarter)
      calculation = calculate_vat_payable(quarter: quarter)

      declaration = {
        period: quarter,
        section1: {
          taxable_sales: calculation[:by_rate][VAT_RATES[:standard]][:base],
          vat_at_20: calculation[:by_rate][VAT_RATES[:standard]][:vat],
          taxable_at_10: calculation[:by_rate][VAT_RATES[:reduced]][:base],
          vat_at_10: calculation[:by_rate][VAT_RATES[:reduced]][:vat],
          export_sales: calculation[:by_rate][VAT_RATES[:export]][:base],
          total_vat: calculation[:vat_outgoing]
        },
        section2: {
          purchases_deductible: calculation[:by_rate][VAT_RATES[:standard]][:purchases_base],
          vat_deductible: calculation[:by_rate][VAT_RATES[:standard]][:purchases_vat],
          purchases_at_10: calculation[:by_rate][VAT_RATES[:reduced]][:purchases_base],
          vat_deductible_at_10: calculation[:by_rate][VAT_RATES[:reduced]][:purchases_vat]
        },
        section3: {
          vat_payable: calculation[:vat_payable],
          previous_declarations: @vat_declarations.last(4),
          payment_due: calculate_payment_due_date(quarter)
        }
      }

      @vat_declarations << declaration
      declaration
    end

    private

    def vat_rate_to_bigdecimal(rate)
      return nil if rate.nil?
      return rate if rate.is_a?(BigDecimal)

      # Если rate - символ, берем из константы
      return VAT_RATES[rate] if rate.is_a?(Symbol)

      # Иначе преобразуем в BigDecimal
      BigDecimal(rate.to_s)
    end

    def vat_rate_equal?(rate1, rate2)
      return rate1.nil? == rate2.nil? if rate1.nil? || rate2.nil?

      rate1 == rate2
    end

    def calculate_vat(amount, rate)
      return BigDecimal('0') if rate.nil? || rate.zero?

      amount * rate
    end

    def breakdown_by_rate(invoices)
      breakdown = {}

      invoices.each do |invoice|
        rate = invoice[:vat_rate] || :exempt
        breakdown[rate] ||= { base: BigDecimal('0'), vat: BigDecimal('0'), count: 0 }
        breakdown[rate][:base] += invoice[:amount]
        breakdown[rate][:vat] += invoice[:vat_amount]
        breakdown[rate][:count] += 1

        type_key = invoice[:type] == :sale ? :sales : :purchases
        breakdown[rate][type_key] ||= BigDecimal('0')
        breakdown[rate][type_key] += invoice[:amount]
      end

      breakdown
    end
  end
end
