# csv-safe

[![Gem Version](https://badge.fury.io/rb/csv-safe.svg)](https://badge.fury.io/rb/csv-safe)

Also hosted on [RubyGems.org](https://rubygems.org/gems/csv-safe).

This gem decorates the built in CSV library to prevent CSV injection attacks. Wherever you would use `CSV` in your code, use `CSVSafe`. The gem will encode your fields in UTF-8.

What this gem does specifically:
 - Override `CSV#<<` to sanitize incoming rows.
 - Override `CSV#initialize` to add a converter that will sanitize fields being read.

A description of CSV injection attacks on [OWASP](https://www.owasp.org/index.php/CSV_Excel_Macro_Injection) 

Made while working at [Influitive](https://influitive.com/). We kept writing similar code to sanitize CSV output, and I couldn't find a gem to do this for us, so I wrote this. 


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'csv-writer-safe'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csv_safe

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
