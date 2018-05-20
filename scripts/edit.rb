# -*- encoding: utf-8 -*-
# edit.rb - v1

require 'json'
require 'base64'
require 'erb'
require './scripts/auth.rb'
require 'open-uri'

class Edit
	def self.call(env)
		@@editor = ERB.new File.open('./scripts/templet/editor.erb').read.force_encoding('UTF-8')
		req = Rack::Request.new(env)
		reserve_path = ['new','login','rss','upload','image','static','markdown_archives','edit']
		if req.get?
			if SimpleAuth.pass?(req)
				markdown_templet = '../markdown_archives/' + req.path.sub('/edit/', '') + '.md'
				input_tips = '请输入新的标题，留空以使用原始标题（此标题将作为访问地址的一部分，中文地址将被自动编码）'

				['200', {'Content-Type' => 'text/html'}, [@@editor.result(binding)]]
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

					raise if !data.has_key?('content-md')
					raise if !data.has_key?('content-html')
				rescue
					return_content = Hash.new
					return_content['success'] = 0
					return_content['message'] = '无法识别的提交格式'
					return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
				end

				# delete origin blog first

				ori_name = req.path.sub('/edit/', '')

				ori_html_path = './data/html/' + ori_name + '.html'
				ori_markdown_path = './data/markdown/' + ori_name + '.md'

				if File::exist?(ori_html_path)
					File::delete(ori_html_path)
				end

				if File::exist?(ori_markdown_path)
					File::delete(ori_markdown_path)
				end

				# the same as new do

				data_uri = nil

				if data['title'] == nil || data['title'] == ''
					data_uri = ori_name
				else
					data['title'].sub!(' ', '_')
					data['title'].sub!('.', '-')

					data_uri = URI.encode data['title']
				end

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
				return_content['message'] = 'Edit Blog Success'
				return_content['url'] = '../' + data_uri

				FileUtils.touch './data/rebuild.stamp'
				
				['201', {'Content-Type' => 'application/json', 'Location' => return_content['url']}, [return_content.to_json]]
			end
		else
			['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end
	end
end