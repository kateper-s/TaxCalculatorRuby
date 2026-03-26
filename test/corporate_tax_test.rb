require_relative "test_helper"

module TaxCalculator
  class CorporateTaxTest < Minitest::Test

    def setup
      @ct = CorporateTax.new
    end

    def test_tax_systems_frozen
      assert CorporateTax::TAX_SYSTEMS.frozen?
    end

    def test_osn_has_20_percent_profit_rate
      assert_equal 0.20, CorporateTax::TAX_SYSTEMS[:osn][:profit_rate]
    end

    def test_usn_income_rate_is_6_percent
      assert_equal 0.06, CorporateTax::TAX_SYSTEMS[:usn_income][:rate]
    end

    def test_usn_income_is_vat_exempt
      assert CorporateTax::TAX_SYSTEMS[:usn_income][:vat_exempt]
    end

    def test_all_expected_systems_present
      %i[osn usn_income usn_income_minus_expenses eshn patent].each do |s|
        assert_includes CorporateTax::TAX_SYSTEMS, s
      end
    end

    def test_osn_requires_vat
      assert CorporateTax::TAX_SYSTEMS[:osn][:vat_required]
    end

    def test_eshn_rate_is_6_percent
      assert_equal 0.06, CorporateTax::TAX_SYSTEMS[:eshn][:rate]
    end

    def test_default_tax_system_is_osn
      assert_equal :osn, @ct.instance_variable_get(:@tax_system)
    end

    def test_fiscal_year_defaults_to_current
      assert_equal Date.today.year, @ct.instance_variable_get(:@fiscal_year)
    end

    def test_custom_tax_system
      ct = CorporateTax.new(tax_system: :usn_income)
      assert_equal :usn_income, ct.instance_variable_get(:@tax_system)
    end

    def test_custom_fiscal_year
      ct = CorporateTax.new(fiscal_year: 2023)
      assert_equal 2023, ct.instance_variable_get(:@fiscal_year)
    end

    def test_transactions_initially_empty
      assert_empty @ct.instance_variable_get(:@transactions)
    end

    def test_assets_initially_empty
      assert_empty @ct.instance_variable_get(:@assets)
    end

    def test_depreciation_method_default_is_linear
      assert_equal :linear, @ct.instance_variable_get(:@depreciation_method)
    end

    # ── add_transaction ───────────────────────────────────────────────────────

    def test_add_transaction_stores_entry
      @ct.add_transaction(date: Date.today, description: "Sale", amount: 50_000, type: :income)
      assert_equal 1, @ct.instance_variable_get(:@transactions).size
    end

    def test_add_transaction_assigns_uuid
      @ct.add_transaction(date: Date.today, description: "Sale", amount: 50_000, type: :income)
      t = @ct.instance_variable_get(:@transactions).first
      assert_match(/\A[0-9a-f\-]{36}\z/, t[:id])
    end

    def test_add_transaction_stores_amount
      @ct.add_transaction(date: Date.today, description: "Expense", amount: 25_000, type: :expense)
      assert_equal 25_000, @ct.instance_variable_get(:@transactions).first[:amount]
    end

    def test_add_transaction_stores_type
      @ct.add_transaction(date: Date.today, description: "Expense", amount: 25_000, type: :expense)
      assert_equal :expense, @ct.instance_variable_get(:@transactions).first[:type]
    end

    def test_add_transaction_stores_vat_rate
      @ct.add_transaction(date: Date.today, description: "Sale", amount: 50_000,
                          type: :income, vat_rate: 0.20)
      assert_equal 0.20, @ct.instance_variable_get(:@transactions).first[:vat_rate]
    end

    def test_add_transaction_stores_date
      date = Date.new(2024, 6, 15)
      @ct.add_transaction(date: date, description: "Sale", amount: 10_000, type: :income)
      assert_equal date, @ct.instance_variable_get(:@transactions).first[:date]
    end

    def test_multiple_transactions_all_stored
      3.times { |i| @ct.add_transaction(date: Date.today, description: "T#{i}", amount: 1_000, type: :income) }
      assert_equal 3, @ct.instance_variable_get(:@transactions).size
    end

    def test_each_transaction_gets_unique_id
      2.times { @ct.add_transaction(date: Date.today, description: "T", amount: 1_000, type: :income) }
      ids = @ct.instance_variable_get(:@transactions).map { |t| t[:id] }
      assert_equal ids.uniq.size, ids.size
    end

    def test_linear_depreciation_annual
      result = @ct.calculate_depreciation(asset_value: 120_000, useful_life: 10, method: :linear)
      assert_in_delta 12_000, result[:annual], 0.01
    end

    def test_linear_depreciation_monthly
      result = @ct.calculate_depreciation(asset_value: 120_000, useful_life: 10, method: :linear)
      assert_in_delta 1_000, result[:monthly], 0.01
    end

    def test_linear_depreciation_schedule_length
      result = @ct.calculate_depreciation(asset_value: 120_000, useful_life: 5, method: :linear)
      assert_equal 5, result[:schedule].size
    end

    def test_linear_depreciation_schedule_remaining_value_decreases
      result = @ct.calculate_depreciation(asset_value: 100_000, useful_life: 5, method: :linear)
      values = result[:schedule].map { |s| s[:remaining_value] }
      assert_equal values, values.sort.reverse
    end

    def test_linear_depreciation_final_remaining_value_is_zero
      result = @ct.calculate_depreciation(asset_value: 100_000, useful_life: 5, method: :linear)
      assert_in_delta 0, result[:schedule].last[:remaining_value], 0.01
    end

    def test_depreciation_default_method_is_linear
      result = @ct.calculate_depreciation(asset_value: 60_000, useful_life: 6)
      assert_in_delta 10_000, result[:annual], 0.01
    end

    def test_depreciation_schedule_has_year_key
      result = @ct.calculate_depreciation(asset_value: 60_000, useful_life: 3, method: :linear)
      assert result[:schedule].first.key?(:year)
    end

    def test_depreciation_schedule_year_numbers
      result = @ct.calculate_depreciation(asset_value: 60_000, useful_life: 3, method: :linear)
      assert_equal [1, 2, 3], result[:schedule].map { |s| s[:year] }
    end

    def test_import_transactions_adds_entries
      csv = "date,description,amount,type,vat_rate\n2024-01-15,Sale,50000,income,0.20\n"
      @ct.import_transactions(csv)
      assert_equal 1, @ct.instance_variable_get(:@transactions).size
    end

    def test_import_transactions_parses_amount
      csv = "date,description,amount,type,vat_rate\n2024-01-15,Sale,75000,income,\n"
      @ct.import_transactions(csv)
      assert_in_delta 75_000, @ct.instance_variable_get(:@transactions).first[:amount], 0.01
    end

    def test_import_transactions_parses_type_as_symbol
      csv = "date,description,amount,type,vat_rate\n2024-01-15,Expense,10000,expense,\n"
      @ct.import_transactions(csv)
      assert_equal :expense, @ct.instance_variable_get(:@transactions).first[:type]
    end

    def test_import_transactions_parses_date
      csv = "date,description,amount,type,vat_rate\n2024-03-20,Sale,1000,income,\n"
      @ct.import_transactions(csv)
      assert_equal Date.new(2024, 3, 20), @ct.instance_variable_get(:@transactions).first[:date]
    end

    def test_import_multiple_csv_rows
      csv = "date,description,amount,type,vat_rate\n" \
            "2024-01-01,Sale 1,10000,income,0.20\n" \
            "2024-02-01,Sale 2,20000,income,0.20\n" \
            "2024-03-01,Expense,5000,expense,0.20\n"
      @ct.import_transactions(csv)
      assert_equal 3, @ct.instance_variable_get(:@transactions).size
    end
    def test_losses_suggestion_when_previous_year_losses_exist
      %w[calculate_profit_tax calculate_investment_credit calculate_losses_benefit
         has_investment_expenses? compare_tax_systems].each do |m|
        @ct.define_singleton_method(m) { |*| {} }
      end
      @ct.define_singleton_method(:has_investment_expenses?) { false }
      @ct.instance_variable_set(:@losses_previous_years, [{ year: 2023, amount: 100_000 }])

      suggestions = @ct.tax_optimization_suggestions
      types = suggestions.map { |s| s[:type] }
      assert_includes types, :losses_carryforward
    end
  end
end
