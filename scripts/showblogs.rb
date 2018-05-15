# new.rb - v1

# require 'json'
# require 'base64'
require "erb"

class ShowBlogs
	def self.call(env)
		req = Rack::Request.new(env)
		if req.get?
			if req.path == '/'
				# show list
				return ['200', {'Content-Type' => 'text/html'}, ['原谅我还没做list']]
			end

			path = './data/html' + req.path + '.html'
			
			if File::exist?(path)

				blog_templet = ERB.new File.open('./scripts/templet/blog_page.erb').read
				markdown_page = File.read(path)
				footer_page = File.read('./scripts/templet/footer.html')
				title = req.path.to_s

				['200', {'Content-Type' => 'text/html'}, [blog_templet.result(binding)]]
			else
				['404', {'Content-Type' => 'text/html'}, ['404 Not Found']]
			end
		else
			return ['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end
	end
end