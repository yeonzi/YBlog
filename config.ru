#\ -w --port 8081 --host 0.0.0.0
# my blog
# config.ru

require './scripts/new.rb'
require './scripts/upload.rb'
require './scripts/showblogs.rb'
require './scripts/login.rb'

map '/new' do
	use Rack::Head
	use Rack::ETag
	run New
end

map '/upload' do
	use Rack::Head
	Rack::TempfileReaper
	run Upload
end

map '/login' do
	use Rack::Head
	run Login
end

map '/image' do
	use Rack::Head
	use Rack::Sendfile
	use Rack::ConditionalGet
	use Rack::ETag
	run Rack::File.new "./data/image"
end

map '/static' do
	use Rack::Head
	use Rack::Sendfile
	use Rack::ConditionalGet
	use Rack::ETag
	run Rack::File.new "./static"
end

map '/' do
	use Rack::Head
	use Rack::ETag
	run ShowBlogs
end