module TaxCalculator
  class TaxReports
    def initialize(taxpayer)
      @taxpayer = taxpayer
      @tax_periods = []
    end

    def annual_report(year)
      personal_tax = @taxpayer.personal_tax&.calculate
      corporate_tax = @taxpayer.corporate_tax&.calculate_profit_tax
      vat = @taxpayer.vat&.calculate_vat_payable
      
      {
        year: year,
        summary: {
          total_tax_paid: (personal_tax&.[](:tax_amount) || 0) + 
                         (corporate_tax&.[](:tax_amount) || 0) +
                         (vat&.[](:vat_payable) || 0),
          by_tax_type: {
            personal_income: personal_tax,
            corporate: corporate_tax,
            vat: vat
          }
        },
        monthly_breakdown: generate_monthly_breakdown(year),
        quarterly_summary: generate_quarterly_summary(year),
        comparisons: {
          vs_last_year: compare_with_last_year(year),
          vs_industry_average: compare_with_industry
        },
        analytics: {
          tax_burden_percentage: calculate_tax_burden,
          growth_indicators: calculate_growth,
          projections: generate_projections
        }
      }
    end

    def export(format: :json, report_type: :annual, year: Date.today.year)
      report = send("#{report_type}_report", year)
      
      case format
      when :json
        JSON.pretty_generate(report)
      when :csv
        convert_to_csv(report)
      when :pdf
        convert_to_pdf(report)
      when :xlsx
        convert_to_excel(report)
      end
    end

    private

    def generate_monthly_breakdown(year)
      (1..12).map do |month|
        {
          month: month,
          income: @taxpayer.income_for_month(year, month),
          tax_paid: @taxpayer.tax_paid_for_month(year, month),
          effective_rate: calculate_monthly_rate(month)
        }
      end
    end
  end
end