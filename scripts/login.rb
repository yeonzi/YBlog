# login.rb - v1

require 'erb'
require 'json'
require 'digest/sha1'

class Login

	def self.call(env)
		req = Rack::Request.new(env)
		login_page = ERB.new File.open('./scripts/templet/login.erb').read
		if req.get?
			login_status = ''
			['200', {'Content-Type' => 'text/html'}, [login_page.result(binding)]]
		elsif req.post?

			if !req.params.has_key?('username') || !req.params.has_key?('password')
				login_status = '无法识别的提交格式'
				return ['200', {'Content-Type' => 'text/html'}, [login_page.result(binding)]]
			end

			user_file = './data/users/' + req.params['username'] + '.json'

			if !File::exist?(user_file)
				login_status = '用户名与密码不正确'
				return ['200', {'Content-Type' => 'text/html'}, [login_page.result(binding)]]
			end

			user_data = JSON.parse(File.read(user_file))

			if req.params['password'] != user_data['password']
				login_status = '用户名或密码不正确'
				return ['200', {'Content-Type' => 'text/html'}, [login_page.result(binding)]]
			end

			session_raw = Time.new.to_i.to_s + user_data['username'] + user_data['password'] + rand(100000000).to_s + 'emmmmm'

			user_data['session'] = Digest::SHA1.hexdigest(session_raw).upcase

			File.write(user_file, user_data.to_json)

			response = Rack::Response.new File.open('./scripts/templet/login_success.html'), '200', {'Content-Type' => 'text/html'}
			response.set_cookie("zssmwy_blog_session", {:value => user_data['session'], :path => "/", :expires => Time.now+7*24*60*60})
			response.set_cookie("zssmwy_blog_loginid", {:value => user_data['username'], :path => "/", :expires => Time.now+7*24*60*60})

			response.finish
		else
			['405', {'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
		end
	end
end