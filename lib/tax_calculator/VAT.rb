module TaxCalculator
  class VAT
    VAT_RATES = {
      standard: 0.20,
      reduced: 0.10,
      super_reduced: 0.0,
      estimated: 0.20/1.20,  
      export: 0.0,
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
        period: quarter || "all",
        vat_outgoing: vat_outgoing,
        vat_incoming: vat_incoming,
        vat_recovered: vat_recovered,
        vat_payable: vat_payable + vat_recovered,
        transactions_count: period_invoices.size,
        by_rate: breakdown_by_rate(period_invoices)
      }
    end

    def purchase_ledger(period: :quarter)
      purchases = @invoices.select { |i| i[:type] == :purchase }
      
      {
        total_purchases: purchases.sum { |i| i[:amount] },
        total_vat: purchases.sum { |i| i[:vat_amount] },
        by_counterparty: group_by_counterparty(purchases),
        by_rate: breakdown_by_rate(purchases),
        deductions_eligible: calculate_eligible_deductions(purchases)
      }
    end

    def sales_ledger(period: :quarter)
      sales = @invoices.select { |i| i[:type] == :sale }
      
      {
        total_sales: sales.sum { |i| i[:amount] },
        total_vat: sales.sum { |i| i[:vat_amount] },
        by_counterparty: group_by_counterparty(sales),
        export_sales: sales.select { |i| i[:vat_rate] == 0.0 },
        taxable_at_standard: sales.select { |i| i[:vat_rate] == 0.20 }
      }
    end

    def proportional_deduction_check
      total_revenue = @invoices.select { |i| i[:type] == :sale }.sum { |i| i[:amount] }
      taxable_revenue = @invoices.select { |i| i[:type] == :sale && i[:vat_rate] }.sum { |i| i[:amount] }
      
      if total_revenue > 0
        proportion = taxable_revenue / total_revenue.to_f
        
        {
          proportion: proportion,
          can_deduct_full: proportion > 0.95,
          must_proportion: proportion < 0.95 && proportion > 0.05,
          adjustment_needed: proportion < 0.05 ? "No deduction allowed" : "Proportional deduction",
          adjustment_calculation: calculate_proportional_adjustment(proportion)
        }
      end
    end

    def calculate_recovery(asset_type:, years_used:, total_vat:)
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
          taxable_sales: calculation[:by_rate][0.20][:base],
          vat_at_20: calculation[:by_rate][0.20][:vat],
          taxable_at_10: calculation[:by_rate][0.10][:base],
          vat_at_10: calculation[:by_rate][0.10][:vat],
          export_sales: calculation[:by_rate][0.0][:base],
          total_vat: calculation[:vat_outgoing]
        },
        section2: {
          purchases_deductible: calculation[:by_rate][0.20][:purchases_base],
          vat_deductible: calculation[:by_rate][0.20][:purchases_vat],
          purchases_at_10: calculation[:by_rate][0.10][:purchases_base],
          vat_deductible_at_10: calculation[:by_rate][0.10][:purchases_vat]
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

    def calculate_vat(amount, rate)
      return 0 if rate.nil? || rate.zero?
      amount * rate
    end

    def breakdown_by_rate(invoices)
      breakdown = {}
      
      invoices.each do |invoice|
        rate = invoice[:vat_rate] || :exempt
        breakdown[rate] ||= { base: 0, vat: 0, count: 0 }
        breakdown[rate][:base] += invoice[:amount]
        breakdown[rate][:vat] += invoice[:vat_amount]
        breakdown[rate][:count] += 1
        
        type_key = invoice[:type] == :sale ? :sales : :purchases
        breakdown[rate][type_key] ||= 0
        breakdown[rate][type_key] += invoice[:amount]
      end
      
      breakdown
    end
  end
end