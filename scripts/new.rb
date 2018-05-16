# new.rb - v1

require 'json'
require 'base64'
require 'erb'
require './scripts/auth.rb'
require 'nokogiri'
require 'open-uri'

class New
	def self.call(env)
		req = Rack::Request.new(env)
		reserve_path = ['new','login','rss','upload','image','static']
		if req.get?
			if SimpleAuth.pass?(req)
				editor = ERB.new File.open('./scripts/templet/editor.erb').read

				markdown_templet = './static/default.md'

				['200', {'Content-Type' => 'text/html'}, [editor.result(binding)]]
			else
				# need login
				['200', {'Content-Type' => 'text/html'}, [File.read('./scripts/templet/login_requested.html')]]
			end
		elsif req.post?
			if !SimpleAuth.pass?(req)
				return_content = Hash.new
				return_content['success'] = 0
				return_content['message'] = 'Login requested'
				return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
			else
				begin
					json = req.body.read
					data = JSON.parse(json)

					raise if !data.has_key?('title')
					raise if !data.has_key?('content-md')
					raise if !data.has_key?('content-html')
				rescue
					puts $@
					puts $!
					puts data
					return_content = Hash.new
					return_content['success'] = 0
					return_content['message'] = '无法识别的提交格式'
					return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
				end

				data['title'].sub!(' ', '_')
				data['title'].sub!('.', '-')

				data_uri = URI.encode data['title']

				if reserve_path.include? data_uri
					return_content = Hash.new
					return_content['success'] = 0
					return_content['message'] = '这个地址被保留了呢，换个地址吧'
					return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
				end

				markdown_path = './data/markdown/' + data_uri + '.md'
				html_path = './data/html/' + data_uri + '.html'

				if File::exist?(html_path) || File::exist?(markdown_path)
					return_content = Hash.new
					return_content['success'] = 0
					return_content['message'] = '这个地址的博客已经存在了，换个地址吧'
					return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
				end

				markdown_file = File.open(markdown_path, 'wb')
				markdown_file.write data['content-md']
				markdown_file.close

				html_file = File.open(html_path, 'wb')
				html_file.write data['content-html']
				html_file.close

				return_content = Hash.new
				return_content['success'] = 1
				return_content['message'] = 'Create Blog Success'
				return_content['url'] = './' + data_uri

				FileUtils.touch './data/rebuild.stamp'
				
				['201', {'Content-Type' => 'application/json', 'Location' => return_content['url']}, [return_content.to_json]]
			end
		else
			['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end
	end
end