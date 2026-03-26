# frozen_string_literal: true

module TaxCalculator
  class CorporateTax
    TAX_SYSTEMS = {
      osn: { name: 'General system', profit_rate: 0.20, vat_required: true },
      usn_income: { name: 'Simplified (income)', rate: 0.06, vat_exempt: true },
      usn_income_minus_expenses: { name: 'Simplified (income-expenses)', rate: 0.15, vat_exempt: true },
      eshn: { name: 'Agricultural', rate: 0.06, vat_exempt: true },
      patent: { name: 'Patent system', rate: :fixed, vat_exempt: true }
    }.freeze
    def initialize(tax_system: :osn, fiscal_year: Date.today.year)
      @tax_system = tax_system
      @fiscal_year = fiscal_year
      @transactions = []
      @assets = []
      @depreciation_method = :linear
      @losses_previous_years = []
      @quarterly_reports = []
    end

    def add_transaction(date:, description:, amount:, type:, vat_rate: nil)
      @transactions << {
        date: date,
        description: description,
        amount: amount,
        type: type,
        vat_rate: vat_rate,
        id: SecureRandom.uuid
      }
    end

    def import_transactions(csv_data)
      CSV.parse(csv_data, headers: true) do |row|
        add_transaction(
          date: Date.parse(row['date']),
          description: row['description'],
          amount: row['amount'].to_f,
          type: row['type'].to_sym,
          vat_rate: row['vat_rate']&.to_f
        )
      end
    end

    def calculate_profit_tax(*)
      income = filter_transactions_by_type(:income)
      expenses = filter_transactions_by_type(:expense)

      {
        total_income: sum_transactions(income),
        total_expenses: sum_transactions(expenses),
        gross_profit: calculate_gross_profit(income, expenses),
        depreciation: calculate_depreciation,
        losses_previous_years: apply_losses_carryforward,
        taxable_base: calculate_taxable_base,
        tax_rate: get_tax_rate,
        tax_amount: calculate_final_tax,
        quarterly_breakdown: calculate_quarterly
      }
    end

    def calculate_depreciation(asset_value:, useful_life:, method: :linear)
      case method
      when :linear
        annual_depreciation = asset_value / useful_life
        monthly_depreciation = annual_depreciation / 12

        {
          annual: annual_depreciation,
          monthly: monthly_depreciation,
          schedule: (1..useful_life).map do |year|
            {
              year: year,
              depreciation: annual_depreciation,
              remaining_value: asset_value - (annual_depreciation * year)
            }
          end
        }
      when :declining_balance
        rate = 2.0 / useful_life
        calculate_declining_balance(asset_value, useful_life, rate)
      end
    end

    def calculate_advance_payments
      quarterly_tax = calculate_profit_tax(period: :quarter)
      {
        q1: quarterly_tax[:tax_amount] * 0.25,
        q2: quarterly_tax[:tax_amount] * 0.25,
        q3: quarterly_tax[:tax_amount] * 0.25,
        q4: quarterly_tax[:tax_amount] * 0.25,
        total: quarterly_tax[:tax_amount],
        monthly_payments: calculate_monthly_payments(quarterly_tax[:tax_amount])
      }
    end

    def tax_optimization_suggestions
      calculate_profit_tax
      suggestions = []
      if @transactions.sum { |t| t[:amount] if t[:type] == :income } < 150_000_000
        suggestions << {
          type: :system_change,
          suggestion: 'Consider switching to USN',
          potential_savings: compare_tax_systems(:usn_income)
        }
      end
      if has_investment_expenses?
        suggestions << {
          type: :investment_benefit,
          suggestion: 'Apply investment tax credit',
          potential_savings: calculate_investment_credit
        }
      end
      if @losses_previous_years.any?
        suggestions << {
          type: :losses_carryforward,
          suggestion: 'Apply losses from previous years',
          potential_savings: calculate_losses_benefit
        }
      end
      suggestions
    end

    def compare_tax_systems
      results = {}

      TAX_SYSTEMS.each_key do |system|
        results[system] = calculate_for_system(system)
      end

      results.sort_by { |_, data| data[:total_tax] }.to_h
    end

    def generate_report(format: :json)
      report_data = {
        company_info: {
          tax_system: @tax_system,
          fiscal_year: @fiscal_year
        },
        financials: calculate_profit_tax,
        advances: calculate_advance_payments,
        recommendations: tax_optimization_suggestions
      }

      case format
      when :json
        JSON.pretty_generate(report_data)
      when :csv
        generate_csv_report(report_data)
      when :pdf
        generate_pdf_report(report_data)
      end
    end

    private

    def calculate_for_system(system)
      case system
      when :osn
        calculate_profit_tax
      when :usn_income
        income = sum_transactions_by_type(:income)
        { total_tax: income * 0.06 }
      when :usn_income_minus_expenses
        income = sum_transactions_by_type(:income)
        expenses = sum_transactions_by_type(:expense)
        profit = income - expenses
        min_tax = income * 0.01
        tax = profit * 0.15
        { total_tax: [tax, min_tax].max }
      end
    end
  end
end
