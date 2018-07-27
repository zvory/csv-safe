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

  private

  def prefix_if_necessary(field)
    if field.is_a?(String) && %w[- = + @].include?(field[0])
      "'" + field
    else
      field
    end
  end

  def sanitize_field(field)
    if field.nil?
      field
    else
      encoded = field.encode(CSV::ConverterEncoding)
      prefix_if_necessary(encoded)
    end
  rescue StandardError # encoding conversion errors
    field
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
