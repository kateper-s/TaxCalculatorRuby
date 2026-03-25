require_relative "test_helper"

module TaxCalculator
  class VATTest < Minitest::Test

    def setup
      @vat = VAT.new
    end

    def test_vat_rates_frozen
      assert VAT::VAT_RATES.frozen?
    end

    def test_standard_rate_is_20_percent
      assert_equal 0.20, VAT::VAT_RATES[:standard]
    end

    def test_reduced_rate_is_10_percent
      assert_equal 0.10, VAT::VAT_RATES[:reduced]
    end

    def test_export_rate_is_zero
      assert_equal 0.0, VAT::VAT_RATES[:export]
    end

    def test_exempt_is_nil
      assert_nil VAT::VAT_RATES[:exempt]
    end

    def test_super_reduced_is_zero
      assert_equal 0.0, VAT::VAT_RATES[:super_reduced]
    end

    def test_calculate_vat_standard_rate
      result = @vat.send(:calculate_vat, 10_000, 0.20)
      assert_in_delta 2_000, result, 0.01
    end

    def test_calculate_vat_reduced_rate
      result = @vat.send(:calculate_vat, 10_000, 0.10)
      assert_in_delta 1_000, result, 0.01
    end

    def test_calculate_vat_zero_rate
      result = @vat.send(:calculate_vat, 10_000, 0.0)
      assert_in_delta 0, result, 0.01
    end

    def test_calculate_vat_nil_rate_returns_zero
      result = @vat.send(:calculate_vat, 10_000, nil)
      assert_in_delta 0, result, 0.01
    end

    def test_calculate_vat_large_amount
      result = @vat.send(:calculate_vat, 1_000_000, 0.20)
      assert_in_delta 200_000, result, 0.01
    end


    def test_real_estate_recovery_annual
      result = @vat.calculate_recovery(asset_type: :real_estate, years_used: 0, total_vat: 100_000)
      assert_in_delta 10_000, result[:annual], 0.01
    end

    def test_real_estate_recovery_schedule_length
      result = @vat.calculate_recovery(asset_type: :real_estate, years_used: 3, total_vat: 100_000)
      assert_equal 7, result[:schedule].size
    end

    def test_real_estate_recovery_total_when_new
      result = @vat.calculate_recovery(asset_type: :real_estate, years_used: 0, total_vat: 100_000)
      assert_in_delta 100_000, result[:total_recovery], 0.01
    end

    def test_real_estate_recovery_partial_use
      result = @vat.calculate_recovery(asset_type: :real_estate, years_used: 5, total_vat: 100_000)
      assert_in_delta 50_000, result[:total_recovery], 0.01
    end

    def test_fixed_asset_annual
      result = @vat.calculate_recovery(asset_type: :fixed_asset, years_used: 0, total_vat: 50_000)
      assert_in_delta 10_000, result[:annual], 0.01
    end

    def test_fixed_asset_recovery_partial_use
      result = @vat.calculate_recovery(asset_type: :fixed_asset, years_used: 2, total_vat: 50_000)
      assert_in_delta 30_000, result[:total_recovery], 0.01
    end

    def test_recovery_returns_required_keys_real_estate
      result = @vat.calculate_recovery(asset_type: :real_estate, years_used: 0, total_vat: 10_000)
      assert result.key?(:total_recovery)
      assert result.key?(:annual)
      assert result.key?(:schedule)
    end

    def test_recovery_returns_required_keys_fixed_asset
      result = @vat.calculate_recovery(asset_type: :fixed_asset, years_used: 0, total_vat: 10_000)
      assert result.key?(:total_recovery)
      assert result.key?(:annual)
    end

    def setup_vat_with_stubs
      vat = VAT.new
      vat.define_singleton_method(:quarter_of_date) { |_d| 1 }
      vat.define_singleton_method(:validate_invoice) { |*| true }
      vat
    end

    def test_add_invoice_creates_entry
      vat = setup_vat_with_stubs
      vat.add_invoice(number: "001", date: Date.today, amount: 10_000,
                      vat_rate: 0.20, counterparty: "ООО Ромашка", type: :sale)
      assert_equal 1, vat.instance_variable_get(:@invoices).size
    end

    def test_add_invoice_stores_vat_amount
      vat = setup_vat_with_stubs
      vat.add_invoice(number: "001", date: Date.today, amount: 10_000,
                      vat_rate: 0.20, counterparty: "ООО Ромашка", type: :sale)
      invoice = vat.instance_variable_get(:@invoices).first
      assert_in_delta 2_000, invoice[:vat_amount], 0.01
    end

    def test_add_invoice_stores_total_with_vat
      vat = setup_vat_with_stubs
      vat.add_invoice(number: "001", date: Date.today, amount: 10_000,
                      vat_rate: 0.20, counterparty: "ООО Ромашка", type: :sale)
      invoice = vat.instance_variable_get(:@invoices).first
      assert_in_delta 12_000, invoice[:total_with_vat], 0.01
    end

    def test_add_invoice_zero_rate_no_vat
      vat = setup_vat_with_stubs
      vat.add_invoice(number: "002", date: Date.today, amount: 5_000,
                      vat_rate: 0.0, counterparty: "Экспорт", type: :sale)
      invoice = vat.instance_variable_get(:@invoices).first
      assert_in_delta 0, invoice[:vat_amount], 0.01
    end

    def test_add_invoice_nil_rate_no_vat
      vat = setup_vat_with_stubs
      vat.add_invoice(number: "003", date: Date.today, amount: 5_000,
                      vat_rate: nil, counterparty: "Льготник", type: :sale)
      invoice = vat.instance_variable_get(:@invoices).first
      assert_in_delta 0, invoice[:vat_amount], 0.01
    end

    def test_add_multiple_invoices
      vat = setup_vat_with_stubs
      3.times do |i|
        vat.add_invoice(number: "00#{i}", date: Date.today, amount: 1_000,
                        vat_rate: 0.20, counterparty: "Клиент", type: :sale)
      end
      assert_equal 3, vat.instance_variable_get(:@invoices).size
    end


    def inject_invoices(vat, invoices)
      vat.instance_variable_set(:@invoices, invoices)
    end

    def sample_invoice(type: :sale, amount: 10_000, rate: 0.20)
      {
        number: SecureRandom.uuid, date: Date.today,
        amount: amount, vat_rate: rate,
        vat_amount: amount * (rate || 0),
        total_with_vat: amount + amount * (rate || 0),
        counterparty: "Test", type: type, quarter: 1, is_valid: true
      }
    end

    def test_no_invoices_returns_nil
      result = @vat.proportional_deduction_check
      assert_nil result
    end
  end
end
