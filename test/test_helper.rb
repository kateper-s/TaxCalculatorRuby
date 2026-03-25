require "minitest/autorun"

require "date"
require "json"
require "csv"
require "securerandom"
require "time"

# Project root is one level above /test
PROJECT_ROOT = File.expand_path("..", __dir__)
LIB_DIR      = File.join(PROJECT_ROOT, "lib")

$LOAD_PATH.unshift(LIB_DIR)      unless $LOAD_PATH.include?(LIB_DIR)
$LOAD_PATH.unshift(PROJECT_ROOT) unless $LOAD_PATH.include?(PROJECT_ROOT)

# Load files by their actual names inside lib/tax_calculator/.
# Handles both PascalCase originals and snake_case renames.
CANDIDATE_NAMES = %w[
  version.rb
  config.rb
  CorporateTax.rb       corporate_tax.rb
  personal_income_tax.rb
  tax_benefits.rb
  tax_deductions.rb
  VAT.rb                vat.rb
  TaxReports.rb         tax_reports.rb
].freeze

CANDIDATE_NAMES.each do |filename|
  full = File.join(LIB_DIR, "tax_calculator", filename)
  require full if File.exist?(full) && !$LOADED_FEATURES.include?(full)
end