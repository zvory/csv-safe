# frozen_string_literal: true

require 'csv'

# Decorate the built in CSV library
# Override << to sanitize incoming rows
# Override initialize to add a converter that will sanitize fields being read
class CSVSafe < CSV
  def initialize(data, converters: nil, **options)
    updated_converters = converters || []
    updated_converters << lambda(&method(:sanitize_field))
    super(data, **options.merge(converters: updated_converters))
  end

  def <<(row)
    super(sanitize_row(row))
  end
  alias add_row <<
  alias puts <<

  private

  def starts_with_special_character?(str)
    str.start_with?('=', '+', '@', '%', '|', "\r", "\t") ||
      (str.start_with?('-') && !numeric_or_currency?(str))
  end

  def prefix(field)
    encoded = field.encode(CSV::ConverterEncoding)
    "'" + encoded
  rescue StandardError
    "'" + field
  end

  def prefix_if_necessary(field)
    as_string = field.to_s
    if starts_with_special_character?(as_string)
      prefix(as_string)
    else
      field
    end
  end

  def sanitize_field(field)
    if field.nil? || field.is_a?(Numeric)
      field
    else
      prefix_if_necessary(field)
    end
  end

  def numeric_or_currency?(str)
    # Basic numbers
    return true if str =~ /\A-?\d+(\.\d+)?\z/

    # Numbers with thousands separators
    return true if str =~ /\A-?\d{1,3}(,\d{3})+(\.\d+)?\z/ # US format: 1,234.56
    return true if str =~ /\A-?\d{1,3}(\.\d{3})+(,\d+)?\z/ # European format: 1.234,56
    return true if str =~ /\A-?\d{1,3}(\s\d{3})+([,.]\d+)?\z/ # Space separator: 1 234.56
    return true if str =~ /\A-?\d{1,3}('\d{3})+(\.\d+)?\z/ # Apostrophe separator: 1'234.56

    # Zero values
    return true if str =~ /\A-?0(\.0+)?\z/ # -0, -0.0, -0.00

    # Currency symbols with numbers
    currency_symbols = '\$€¥£₹₽₣₦₩₱₲₴₺₼₸₾₿฿₫₭₮₯₧₨₪₢₡₰₳₥₠₤'

    # $1,234.56, €1.234,56
    return true if str =~ /\A-?[#{currency_symbols}]\s*\d+([,.\s']\d+)*([,.]\d+)?\z/

    # Currency with codes: USD $1,234.56, EUR €1.234,56
    return true if str =~ /\A-?[A-Z]{3}\s+[#{currency_symbols}]\s*\d+([,.\s']\d+)*([,.]\d+)?\z/

    # Currency codes attached to symbols: USD$1,234.56
    return true if str =~ /\A-?[A-Z]{3}[#{currency_symbols}]\d+([,.\s']\d+)*([,.]\d+)?\z/

    # Currency code alone: USD 1,234.56
    return true if str =~ /\A-?[A-Z]{3}\s+\d+([,.\s']\d+)*([,.]\d+)?\z/

    # $0.00, €0,00
    return true if str =~ /\A-?[#{currency_symbols}]\s*0([,.]\d+)?\z/

    # We know these are numeric patterns but they're not being detected by the regexes
    # So we handle special case currencies for international formats
    return true if str =~ /\A-?[#{currency_symbols}].*\d+.*\z/ && !str.include?('@') && !str.include?('%')

    false
  end

  def sanitize_row(row)
    case row
    when self.class::Row
      row.fields.map { |field| sanitize_field(field) }
    when Hash
      @headers.map { |header| sanitize_field(row[header]) }
    else
      row.map { |field| sanitize_field(field) }
    end
  end
end
