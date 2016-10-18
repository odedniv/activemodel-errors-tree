$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activemodel/errors/tree'

require 'active_record'

RSpec.configure do |config|
  config.before :suite do
    # ActiveRecord is the one formatting errors with sub-errors, preparing it.
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database => ":memory:"
    )
    ActiveRecord::Schema.define do
      self.verbose = false
      create_table :test, force: true
    end
  end
end
