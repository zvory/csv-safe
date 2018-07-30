require 'csv'

# Decorate the built in CSV library
# Override << to sanitize incoming rows
# Override initialize to add a converter that will sanitize fields being read
class CSVSafe < CSV
  def initialize(data, options = {})
    options[:converters] = [] if options[:converters].nil?
    options[:converters] << lambda(&method(:sanitize_field))
    super
  end

  def <<(row)
    super(sanitize_row(row))
  end
  alias_method :add_row, :<<
  alias_method :puts,    :<<

  private

  # TODO: performance test if i'm adding
  # too many method calls to hot code
  def starts_with_special_character?(str)
    %w[- = + @].include?(str[0])
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

  def sanitize_row(row)
    case row
    when self.class::Row
      then row.fields.map { |field| sanitize_field(field) }
    when Hash
      then @headers.map { |header| sanitize_field(row[header]) }
    else
      row.map { |field| sanitize_field(field) }
    end
  end
end
