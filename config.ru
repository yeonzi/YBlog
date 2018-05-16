#\ -w --port 8081 --host 0.0.0.0
# my blog
# config.ru

require './scripts/new.rb'
require './scripts/upload.rb'
require './scripts/showblogs.rb'
require './scripts/login.rb'

map '/new' do
	use Rack::ETag
	run New
end

map '/upload' do
	Rack::TempfileReaper
	run Upload
end

map '/login' do
	run Login
end

map '/image' do
	use Rack::Sendfile
	use Rack::ETag
	run Rack::File.new "./image"
end

map '/static' do
	use Rack::Sendfile
	use Rack::ETag
	run Rack::File.new "./static"
end

map '/' do
	use Rack::ETag
	run ShowBlogs
end