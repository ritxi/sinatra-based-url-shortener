require File.dirname(__FILE__) + '/../sinatra-based-url-shortener'
%w( spec capybara capybara/dsl rack/test ).each {|lib| require lib }

def transactional_specs rspec_config
  rspec_config.before do
    @_spec_transaction = DataMapper::Transaction.new DataMapper.repository(:default).adapter
    @_spec_transaction.begin
    DataMapper.repository(:default).adapter.push_transaction @_spec_transaction
  end 
  rspec_config.after do
    DataMapper.repository(:default).adapter.pop_transaction
    @_spec_transaction.rollback
  end 
end

DataMapper.setup :default, 'sqlite3::memory:'
DataMapper.auto_migrate!

include Capybara
Capybara.app = SinatraBasedUrlShortener.new

Spec::Runner.configure do |config|
  transactional_specs(config)
end
