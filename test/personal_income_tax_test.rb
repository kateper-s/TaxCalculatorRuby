require_relative "test_helper"

module TaxCalculator
  class PersonalIncomeTaxTest < Minitest::Test

    def test_progressive_rates_frozen
      assert PersonalIncomeTax::PROGRESSIVE_RATES.frozen?
    end

    def test_progressive_rates_starts_at_13_percent
      assert_equal 0.13, PersonalIncomeTax::PROGRESSIVE_RATES.first[:rate]
    end

    def test_progressive_rates_has_three_brackets
      assert_equal 3, PersonalIncomeTax::PROGRESSIVE_RATES.size
    end

    def test_progressive_rates_second_threshold
      assert_equal 5_000_000, PersonalIncomeTax::PROGRESSIVE_RATES[1][:threshold]
    end

    def test_residency_status_default_is_resident
      pit = PersonalIncomeTax.new(annual_income: 100_000)
      assert_equal :resident, pit.instance_variable_get(:@residency_status)
    end

    def test_default_annual_income_stored
      pit = PersonalIncomeTax.new(annual_income: 500_000)
      assert_equal 500_000, pit.instance_variable_get(:@annual_income)
    end

    def test_dependents_default_zero
      pit = PersonalIncomeTax.new
      assert_equal 0, pit.instance_variable_get(:@dependents)
    end

    def test_deductions_initially_empty
      pit = PersonalIncomeTax.new
      assert_empty pit.instance_variable_get(:@deductions)
    end

    def test_additional_incomes_initially_empty
      pit = PersonalIncomeTax.new
      assert_empty pit.instance_variable_get(:@additional_incomes)
    end

    def test_add_income_stores_entry
      pit = PersonalIncomeTax.new(annual_income: 0)
      pit.add_income(source: "Freelance", amount: 100_000)
      incomes = pit.instance_variable_get(:@additional_incomes)
      assert_equal 1, incomes.size
    end

    def test_add_income_stores_amount
      pit = PersonalIncomeTax.new(annual_income: 0)
      pit.add_income(source: "Rent", amount: 200_000)
      entry = pit.instance_variable_get(:@additional_incomes).first
      assert_equal 200_000, entry[:amount]
    end

    def test_add_income_default_type_is_salary
      pit = PersonalIncomeTax.new(annual_income: 0)
      pit.add_income(source: "Job", amount: 100_000)
      entry = pit.instance_variable_get(:@additional_incomes).first
      assert_equal :salary, entry[:type]
    end

    def test_add_income_taxable_flag_stored
      pit = PersonalIncomeTax.new(annual_income: 0)
      pit.add_income(source: "Gift", amount: 50_000, is_taxable: false)
      entry = pit.instance_variable_get(:@additional_incomes).first
      refute entry[:is_taxable]
    end

    def test_add_multiple_incomes
      pit = PersonalIncomeTax.new(annual_income: 0)
      pit.add_income(source: "Job",  amount: 300_000)
      pit.add_income(source: "Rent", amount: 200_000)
      assert_equal 2, pit.instance_variable_get(:@additional_incomes).size
    end

    # ── self_employed / sole_proprietor (private, tested via compare) ─────────

    def test_self_employed_rate_under_2_4m_is_4_percent
      pit = PersonalIncomeTax.new(annual_income: 1_000_000)
      tax = pit.send(:calculate_self_employed_tax)
      assert_in_delta 40_000, tax, 1
    end

    def test_self_employed_rate_above_2_4m_is_6_percent
      pit = PersonalIncomeTax.new(annual_income: 3_000_000)
      tax = pit.send(:calculate_self_employed_tax)
      assert_in_delta 180_000, tax, 1
    end

    def test_sole_proprietor_rate_is_6_percent
      pit = PersonalIncomeTax.new(annual_income: 1_000_000)
      tax = pit.send(:calculate_sole_proprietor_tax)
      assert_in_delta 60_000, tax, 1
    end

    def test_self_employed_boundary_exactly_2_4m
      pit = PersonalIncomeTax.new(annual_income: 2_400_000)
      tax = pit.send(:calculate_self_employed_tax)
      assert_in_delta 96_000, tax, 1   # 2_400_000 * 0.04
    end
  end
end
