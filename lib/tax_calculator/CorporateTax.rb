module TaxCalculator
  class CorporateTax
    TAX_SYSTEMS = {
      osn: { name: "General system", profit_rate: 0.20, vat_required: true },
      usn_income: { name: "Simplified (income)", rate: 0.06, vat_exempt: true },
      usn_income_minus_expenses: { name: "Simplified (income-expenses)", rate: 0.15, vat_exempt: true },
      eshn: { name: "Agricultural", rate: 0.06, vat_exempt: true },
      patent: { name: "Patent system", rate: :fixed, vat_exempt: true }
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

    def calculate_profit_tax(period: :year)
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
end