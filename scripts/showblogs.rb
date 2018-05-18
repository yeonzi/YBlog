# -*- encoding: utf-8 -*-
# showblogs.rb - v1

# require 'json'
# require 'base64'
require 'erb'
require 'nokogiri'
require './scripts/auth.rb'
require './settings.rb'
require 'open-uri'

class ShowBlogs
	@@footer_page = File.read('./scripts/templet/footer.html').force_encoding('UTF-8')
	@@blog_templet = ERB.new File.open('./scripts/templet/blog_page.erb').read.force_encoding('UTF-8')
	@@list_templet = ERB.new File.open('./scripts/templet/blog_list.erb').read.force_encoding('UTF-8')
	@@rss_templet = ERB.new File.open('./scripts/templet/rss.erb').read.force_encoding('UTF-8')
	@@blog_list = nil

	def self.build_list()
		# Gen Blog list

		if !File::exist?('./data/rebuild.stamp') && @@blog_list != nil
			# no need to rebuild list
			return @@blog_list
		end

		if File::exist?('./data/rebuild.stamp')
			File::delete('./data/rebuild.stamp')
		end

		puts 'Building List'

		new_blog_list = Array.new

		Dir.foreach('./data/html') { |f|
			next if f == '.' || f == '..'
			next if f[0] == '.'
			path = './data/html/' + f
			
			item = Hash.new

			item[:file_path] = path
			item[:path] = './' + f.sub(/.html$/,'')
			item[:full_path] = $url_base + f.sub(/.html$/,'')

			blog_page = File.read(path).force_encoding('UTF-8')
			html_doc = Nokogiri::HTML(blog_page)

			item[:time] = File.mtime(path).getlocal($timezone)
			item[:modified] = item[:time].to_i

			if html_doc.css("h1").first != nil
				item[:title] = html_doc.css("h1").first.content.force_encoding('UTF-8')
			else
				item[:title] = URI.decode( f.sub(/.html$/,'') ).encode(:xml => :text)
			end

			if html_doc.css("img").first != nil
				item[:image] = html_doc.css("img").first.attr('src')
			else
				item[:image] = nil
			end

			item[:abstract] = ''

			if html_doc.css("p") != nil
				html_doc.css("p").each { |tag|
					item[:abstract] = item[:abstract] + tag.content + ' '

					if item[:abstract].length >= 100
						break
					end
				}

				item[:abstract] = item[:abstract][0,100] + ' ...'
			else
				item[:abstract] = '(null)'
			end

			new_blog_list << item
		}

		new_blog_list.sort_by! { |item| item[:modified] }
		new_blog_list.reverse!

		@@blog_list = new_blog_list

		return @@blog_list
	end

	def self.call(env)
		start_time = (Time.now.to_f * 1000).to_i
		req = Rack::Request.new(env)
		if req.get?
			if req.path == '/'
				# show list
				self.build_list()

				blog_list = @@blog_list[0,10]
				footer_page  = @@footer_page
				login_btn = nil

				if SimpleAuth.pass?(req)
					login_href = './new'
					login_cnt = '2'
				else
					login_href = './login'
					login_cnt = '10'
				end

				end_time = (Time.now.to_f * 1000).to_i
				server_info = 'Building Time: ' + (end_time - start_time).to_s + 'ms'

				return ['200', {'Content-Type' => 'text/html'}, [@@list_templet.result(binding)]]
			elsif req.path == '/rss'
				# show RSS
				self.build_list()

				rss_list = @@blog_list

				return ['200', {'Content-Type' => 'application/rss+xml'}, [@@rss_templet.result(binding)]]
			end

			# Start request

			path = './data/html' + req.path + '.html'
			
			if File::exist?(path)

				footer_page  = @@footer_page
				blog_templet = @@blog_templet

				blog_page = File.read(path).force_encoding('UTF-8')
				changed_time = File.mtime(path).getlocal($timezone)
				html_doc = Nokogiri::HTML(blog_page)
				
				if html_doc.css("h1").first != nil
					title = html_doc.css("h1").first.content
				else
					title = URI.decode( req.path.sub('/','') ).force_encoding('UTF-8')
				end

				if SimpleAuth.pass?(req)
					login_href = './new'
					login_cnt = '2'
				else
					login_href = './login'
					login_cnt = '10'
				end
				
				end_time = (Time.now.to_f * 1000).to_i

				server_info = 'Last Modified: ' + changed_time.to_s + ', Loading Time: ' + (end_time - start_time).to_s + 'ms'

				['200', {'Content-Type' => 'text/html'}, [blog_templet.result(binding)]]
			else
				['404', {'Content-Type' => 'text/html'}, ['404 Not Found']]
			end
		else
			return ['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end
	end
end