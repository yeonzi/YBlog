# -*- encoding: utf-8 -*-
# showblogs.rb - v1

# require 'json'
# require 'base64'
require 'erb'
require 'nokogiri'
require './scripts/auth.rb'
require './settings.rb'
require 'open-uri'

class Delete
	@@infopage = ERB.new File.open('./scripts/templet/infopage.erb').read.force_encoding('UTF-8')

	def self.call(env)
		req = Rack::Request.new(env)

		# check method
		if !req.get?
			return ['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end

		# check auth
		if !SimpleAuth.pass?(req)
			return ['403', {'Content-Type' => 'text/plain'}, ['403 Forbidden']]
		end

		file_name = req.path.sub('/delete/', '')

		html_path = './data/html/' + file_name + '.html'
		markdown_path = './data/markdown/' + file_name + '.md'

		if File::exist?(html_path)
			File::delete(html_path)
		end

		if File::exist?(markdown_path)
			File::delete(markdown_path)
		end

		FileUtils.touch './data/rebuild.stamp'

		puts "Blog #{file_name} deleted."

		jumpto = '../'
		info_title = 'Blog已删除'
		info_content = nil

		['200', {'Content-Type' => 'text/html'}, [@@infopage.result(binding)]]
	end
end