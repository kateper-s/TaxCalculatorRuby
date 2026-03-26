# frozen_string_literal: true

module TaxCalculator
  class PersonalIncomeTax
    PROGRESSIVE_RATES = [
      { threshold: 0, rate: 0.13 },
      { threshold: 5_000_000, rate: 0.15 },
      { threshold: 10_000_000, rate: 0.18 }
    ].freeze

    def initialize(annual_income: 0, residency_status: :resident,
                   period: :year, currency: :rub, dependents: 0)
      @annual_income = annual_income
      @residency_status = residency_status
      @period = period
      @currency = currency
      @dependents = dependents
      @deductions = []
      @benefits = []
      @additional_incomes = []
    end

    def add_income(source:, amount:, type: :salary, is_taxable: true)
      @additional_incomes << {
        source: source,
        amount: amount,
        type: type,
        is_taxable: is_taxable,
        date: Time.now
      }
    end

    def calculate
      total_income = calculate_total_income
      taxable_income = apply_deductions(total_income)
      apply_benefits(taxable_income)

      {
        total_income: total_income,
        deductions_total: @deductions.sum { |d| d[:amount] },
        taxable_income: taxable_income,
        tax_amount: calculate_tax_by_rate(taxable_income),
        effective_rate: (calculate_tax_by_rate(taxable_income) / total_income.to_f * 100).round(2),
        breakdown: tax_breakdown
      }
    end

    def calculate_monthly
      months = (1..12).map do |month|
        monthly_income = @annual_income / 12
        {
          month: month,
          income: monthly_income,
          tax: calculate_monthly_tax(monthly_income, month),
          cumulative_tax: cumulative_tax_by_month(month)
        }
      end

      generate_report(months)
    end

    def forecast(next_year_income_growth: 0.1)
      projected_income = @annual_income * (1 + next_year_income_growth)

      {
        current_tax: calculate[:tax_amount],
        projected_tax: self.class.new(
          annual_income: projected_income,
          residency_status: @residency_status
        ).calculate[:tax_amount],
        difference: projected_tax - current_tax,
        recommendations: generate_recommendations(projected_income)
      }
    end

    def compare_with_alternative(tax_system: :self_employed)
      alternative_tax = case tax_system
                        when :self_employed
                          calculate_self_employed_tax
                        when :sole_proprietor
                          calculate_sole_proprietor_tax
                        end

      {
        current_system: { name: :employee, tax: calculate[:tax_amount] },
        alternative_system: { name: tax_system, tax: alternative_tax },
        savings: calculate[:tax_amount] - alternative_tax,
        recommendation: if calculate[:tax_amount] > alternative_tax
                          "Consider switching to #{tax_system}"
                        else
                          'Stay with current system'
                        end
      }
    end

    private

    def calculate_self_employed_tax
      rate = @annual_income > 2_400_000 ? 0.06 : 0.04
      @annual_income * rate
    end

    def calculate_sole_proprietor_tax
      @annual_income * 0.06
    end
  end
end
