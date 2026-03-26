require "minitest/autorun"

require "date"
require "json"
require "csv"
require "securerandom"
require "time"

PROJECT_ROOT = File.expand_path("..", __dir__)
LIB_DIR      = File.join(PROJECT_ROOT, "lib")

$LOAD_PATH.unshift(LIB_DIR)      unless $LOAD_PATH.include?(LIB_DIR)
$LOAD_PATH.unshift(PROJECT_ROOT) unless $LOAD_PATH.include?(PROJECT_ROOT)

CANDIDATE_NAMES = %w[
  version.rb
  config.rb
  corporate_tax.rb       corporate_tax.rb
  personal_income_tax.rb
  tax_benefits.rb
  tax_deductions.rb
  vat.rb                vat.rb
  tax_reports.rb         tax_reports.rb
].freeze

CANDIDATE_NAMES.each do |filename|
  full = File.join(LIB_DIR, "tax_calculator", filename)
  require full if File.exist?(full) && !$LOADED_FEATURES.include?(full)
end