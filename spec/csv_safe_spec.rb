# rubocop:disable Metrics/BlockLength
require 'csv-safe'
require 'pp'

RSpec.describe CSVSafe do
  it 'has a version number' do
    expect(CSVSafe::VERSION).not_to be nil
  end

  describe '#sanitize_field' do
    subject { CSVSafe.new('').send(:sanitize_field, field) }

    context 'with a nil field' do
      let(:field) { nil }
      it { should be_nil }
      it 'should not error' do
        expect { subject }.to_not raise_error
      end
    end

    context 'with a field that does not require sanitization' do
      context 'because it is a plain string' do
        let(:field) { 'Jane Doe' }
        it { should eq field }
      end

      context 'because it a positive number' do
        let(:field) { 123 }
        it { should eq field }
      end

      context 'because it a negative number' do
        let(:field) { -123 }
        it { should eq field }
      end
    end

    context 'with a field that starts with a +' do
      let(:field) { "+=-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'+=-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a \r' do
      let(:field) { "\r2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'\r2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a \t' do
      let(:field) { "\t2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'\t2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a @' do
      let(:field) { "@=-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'@=-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a -' do
      let(:field) { "-=-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'-=-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a =' do
      let(:field) { "==-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'==-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a %' do
      let(:field) { "%0A-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'%0A-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that starts with a %' do
      let(:field) { "|-2+3+cmd|' /C calc'!'E2'" }
      let(:expected) { "'|-2+3+cmd|' /C calc'!'E2'" }
      it { should eq expected }
    end

    context 'with a field that is a date' do
      let(:field) { Time.now }
      it { should eq field }
      it 'should not error' do
        expect { subject }.to_not raise_error
      end
    end

    context 'with negative numbers' do
      subject { (CSVSafe.new('') << row).string }

      context 'with a simple negative number' do
        let(:row) { ['-24.34', '2'] }
        it { should eq "-24.34,2\n" }
      end

      context 'with basic negative currency values (USD, EUR, GBP, JPY)' do
        let(:row) { ['-$2,000.00', '-€1,000.00', '-£3,500.75', '-¥5,000'] }
        it { should eq "\"-$2,000.00\",\"-€1,000.00\",\"-£3,500.75\",\"-¥5,000\"\n" }
      end

      context 'with complex currency formats using various separators' do
        let(:row) { ['-$2,000,000.00', '-€ 1.000,00', '-£3.500,75', '-¥5,000,000'] }
        it { should eq "\"-$2,000,000.00\",\"-€ 1.000,00\",\"-£3.500,75\",\"-¥5,000,000\"\n" }
      end

      context 'with currency codes before symbols' do
        let(:row) { ['-USD $1,234.56', '-EUR €1.234,56', '-GBP £1,234.56', '-JPY ¥1,234'] }
        it { should eq "\"-USD $1,234.56\",\"-EUR €1.234,56\",\"-GBP £1,234.56\",\"-JPY ¥1,234\"\n" }
      end

      context 'with currency codes attached to symbols' do
        let(:row) { ['-USD$1,234.56', '-EUR€1.234,56', '-GBP£1,234.56', '-JPY¥1,234'] }
        it { should eq "\"-USD$1,234.56\",\"-EUR€1.234,56\",\"-GBP£1,234.56\",\"-JPY¥1,234\"\n" }
      end

      context 'with currency codes alone' do
        let(:row) { ['-USD 1,234.56', '-EUR 1.234,56', '-GBP 1,234.56', '-JPY 1,234'] }
        it { should eq "\"-USD 1,234.56\",\"-EUR 1.234,56\",\"-GBP 1,234.56\",\"-JPY 1,234\"\n" }
      end

      context 'with other international currencies' do
        let(:row) do
          [
            '-₹1,00,000.00', # Indian Rupee
            '-₽1 234,56',     # Russian Ruble
            "-₣1'234.56",     # Swiss Franc
            '-₦1,234.56',     # Nigerian Naira
            '-₩1,234',        # Korean Won
            '-₱1,234.56',     # Philippine Peso
            '-₴1 234,56',     # Ukrainian Hryvnia
            '-₺1.234,56'      # Turkish Lira
          ]
        end
        it {
          should eq "\"-₹1,00,000.00\",\"-₽1 234,56\",-₣1'234.56,\"-₦1,234.56\",\"-₩1,234\",\"-₱1,234.56\",\"-₴1 234,56\",\"-₺1.234,56\"\n"
        }
      end

      context 'with mixed values' do
        let(:row) { ['normal text', '-24.34', '-$2,000.00', '@dangerous', '-not-numeric'] }
        it { should eq "normal text,-24.34,\"-$2,000.00\",'@dangerous,'-not-numeric\n" }
      end

      context 'with non-standard numeric formats' do
        let(:row) do
          [
            '-1,234,567.89', # Standard US thousands separator
            '-1.234.567,89',      # European format
            '-1 234 567,89',      # Space as thousands separator
            "-1'234'567.89"       # Apostrophe as thousands separator
          ]
        end
        it { should eq "\"-1,234,567.89\",\"-1.234.567,89\",\"-1 234 567,89\",-1'234'567.89\n" }
      end

      context 'with scientific notation' do
        let(:row) { ['-1.23e4', '-1.23E+4', '-1.23e-4'] }
        it { should eq "'-1.23e4,'-1.23E+4,'-1.23e-4\n" }
      end

      context 'with zero values in different formats' do
        let(:row) { ['-0', '-0.0', '-0.00', '-$0.00', '-€0,00'] }
        it { should eq "-0,-0.0,-0.00,-$0.00,\"-€0,00\"\n" }
      end

      context 'with negative percentages' do
        let(:row) { ['-10%', '-10.5%', '-10,5%'] }
        it { should eq "'-10%,'-10.5%,\"'-10,5%\"\n" }
      end

      context 'with other special negative values' do
        let(:row) { ['-∞', '-NaN', '-Inf'] }
        it { should eq "'-∞,'-NaN,'-Inf\n" }
      end
    end

    # TODO: this file is too big?

    context 'with a field that is a non-String' do
      context 'when the `to_s` does not require sanitization' do
        class ByPassSafe
          def self.to_s
            'Hello World'
          end
        end
        let(:field) { ByPassSafe }
        it 'should not error' do
          expect { subject }.to_not raise_error
        end
      end

      context 'when the `to_s` does require sanitization' do
        class ByPassDangerous
          def self.to_s
            '@Hello World'
          end
        end
        let(:field) { ByPassDangerous }
        it { should eq "'@Hello World" }
        it 'should not error' do
          expect { subject }.to_not raise_error
        end
      end
      # TODO: tests to make sure you can't use broken encodings
    end

    describe '#sanitize_row' do
      before(:all) do
        CSV_Instance = CSVSafe.new('')
      end
      subject { CSV_Instance.send(:sanitize_row, row) }

      context 'when the row is a CSV::Row' do
        context "when the fields don't require sanitization" do
          let(:fields) { %w[Jane 30] }
          let(:row) { CSV::Row.new(%w[Name Age], fields) }
          it { should eq fields }
        end

        context 'when the fields require sanitization' do
          let(:fields) { ['+Jane', '-30'] }
          let(:expected) { ["'+Jane", '-30'] }
          let(:row) { CSV::Row.new(%w[Name Age], fields) }
          it { should eq expected }
        end
      end

      context 'when the row is a Hash' do
        before do
          CSV_Instance.instance_variable_set(:@headers, %i[Name Age])
        end
        context "when the fields don't require sanitization" do
          let(:row) { { Name: 'Jane', Age: '30' } }
          let(:expected) { %w[Jane 30] }
          it { should eq expected }
        end

        context 'when the fields require sanitization' do
          let(:row) { { Name: '+Jane', Age: '@30' } }
          let(:expected) { ["'+Jane", "'@30"] }

          it { should eq expected }
        end
      end

      context 'when the row is an array' do
        context "when the fields don't require sanitization" do
          let(:row) { %w[Jane 30] }
          it { should eq row }
        end

        context 'when the fields require sanitization' do
          let(:row) { ['+Jane', '-30'] }
          let(:expected) { ["'+Jane", '-30'] }
          it { should eq expected }
        end
      end
    end

    describe '.converters' do
      it 'should exist' do
        expect(CSVSafe.new('').converters
          .any? { |converter| converter.is_a? Proc }).to eq true
      end
    end

    describe '#<<' do
      subject { (CSVSafe.new('') << row).string }

      def arr_to_line(arr)
        arr.join(',') + "\n"
      end

      context 'with a row that does not require sanitization' do
        let(:row) { "123,John Doe,    abc     de, /!@\#$%^&*()_+".split(',') }

        it { should eq arr_to_line(row) }
      end

      context 'with a row that contains dates' do
        let(:row) do
          ['hi mom', Time.now]
        end
        it { should eq arr_to_line(row) }
        it 'should not raise an error' do
          expect { subject }.to_not raise_error
        end
      end

      context 'with a row that requires sanitization' do
        context 'because it starts with an @' do
          let(:row) do
            ['@hi']
          end

          let(:expected) do
            ["'@hi"]
          end
          it { should eq arr_to_line(expected) }
        end

        context 'because it starts with a -' do
          let(:row) do
            ["--2+3+cmd|' /C calc'!'E2'"]
          end

          let(:expected) do
            ["'--2+3+cmd|' /C calc'!'E2'"]
          end
          it { should eq arr_to_line(expected) }
        end

        context 'because it starts with an =' do
          let(:row) do
            ["=-2+3+cmd|' /C calc'!'E2'"]
          end

          let(:expected) do
            ["'=-2+3+cmd|' /C calc'!'E2'"]
          end
          it { should eq arr_to_line(expected) }
        end

        context 'because it starts with a +' do
          let(:row) do
            ["+-2+3+cmd|' /C calc'!'E2'"]
          end

          let(:expected) do
            ["'+-2+3+cmd|' /C calc'!'E2'"]
          end
          it { should eq arr_to_line(expected) }
        end

        context 'because it starts with a %' do
          let(:row) do
            ["%0A-2+3+cmd|' /C calc'!'E2'"]
          end

          let(:expected) do
            ["'%0A-2+3+cmd|' /C calc'!'E2'"]
          end
          it { should eq arr_to_line(expected) }
        end
      end
    end
  end

  # TODO: should probably make the tests compare against vanilla CSV actually
  describe 'compared to vanilla CSV' do
    context 'writing to a string using <<' do
      # rubocop:disable Lint/AmbiguousOperator
      subject do
        CSVSafe.generate &block
      end
      let(:expected) { CSV.generate &block }
      # rubocop:enable Lint/AmbiguousOperator

      context 'when the CSV does not need sanitization' do
        let(:block) do
          proc do |csv|
            csv << %w[row of CSV data]
            csv.add_row %w[another row]
          end
        end

        it { should eq expected }
      end

      context 'when the CSV does need sanization' do
        let(:block) do
          proc do |csv|
            csv << ['+row', '@of', 'CSV', 'data']
            csv.puts ['=another', '-row']
          end
        end
        it { should_not eq expected }
      end
    end

    context 'reading from a string using initialization' do
      subject { CSVSafe.new(String.new(csv)).gets }
      context 'when the CSV does not need sanitization' do
        let(:csv) { 'CSV,data,String' }

        let(:expected) { CSV.new(csv).gets }
        it { should eq expected }
      end

      context 'when the CSV does sanitization' do
        let(:csv) { '+CSV,-data,@String' }
        let(:expected) { CSV.new(csv).gets }
        it { should_not eq expected }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
