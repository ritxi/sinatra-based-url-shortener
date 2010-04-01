require File.dirname(__FILE__) + '/sinatra-based-url-shortener'

dev_db = "sqlite3://#{ File.expand_path(File.dirname(__FILE__) + '/development.sqlite3') }"

DataMapper.setup :default, ENV['DATABASE_URL'] || dev_db
DataMapper.auto_upgrade!

run SinatraBasedUrlShortener.new
