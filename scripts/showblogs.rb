# new.rb - v1

# require 'json'
# require 'base64'
require 'erb'
require 'nokogiri'
require './scripts/auth.rb'
require './settings.rb'

class ShowBlogs
	@@footer_page = File.read('./scripts/templet/footer.html')
	@@blog_templet = ERB.new File.open('./scripts/templet/blog_page.erb').read
	@@blog_list = nil

	def self.build_list()
		if !File::exist?('./data/rebuild.stamp') && @@blog_list != nil
			# no need to rebuild list
			return @@blog_list
		end

		if File::exist?('./data/rebuild.stamp')
			File::delete('./data/rebuild.stamp')
		end

		puts 'Building List'

		@@blog_list = Array.new

		Dir.foreach('./data/html') { |f|
			next if f == '.' || f == '..'
			path = './data/html/' + f
			
			item = Hash.new

			item[:full_path] = path
			item[:path] = './' + f.sub(/.html$/,'')

			blog_page = File.read(path)
			html_doc = Nokogiri::HTML(blog_page)

			item[:time] = File.mtime(path).getlocal($timezone)
			item[:modified] = item[:time].to_i

			if html_doc.css("h1").first != nil
				item[:title] = html_doc.css("h1").first.content
			else
				item[:title] = f.sub(/.html$/,'')
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
						item[:abstract] = item[:abstract] + ' ...'
						break
					end
				}
			end

			@@blog_list << item
		}

		@@blog_list.sort_by! { |item| item[:modified] }
		@@blog_list.reverse!

		return @@blog_list
	end

	def self.call(env)
		start_time = (Time.now.to_f * 1000).to_i
		req = Rack::Request.new(env)
		if req.get?
			if req.path == '/'
				# show list
				self.build_list()

				list_templet = ERB.new File.open('./scripts/templet/blog_list.erb').read

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

				return ['200', {'Content-Type' => 'text/html'}, [list_templet.result(binding)]]
			end

			path = './data/html' + req.path + '.html'
			
			if File::exist?(path)

				footer_page  = @@footer_page
				blog_templet = @@blog_templet

				blog_page = File.read(path)
				changed_time = File.mtime(path).getlocal($timezone)
				html_doc = Nokogiri::HTML(blog_page)
				
				if html_doc.css("h1").first != nil
					title = html_doc.css("h1").first.content
				else
					title = req.path.sub('/','')
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