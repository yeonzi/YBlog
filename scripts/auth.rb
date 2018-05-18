# -*- encoding: utf-8 -*-
# auth.rb - v1

require 'json'

module SimpleAuth
	def self.pass?(req)

		if !req.cookies.has_key?('zssmwy_blog_session') || !req.cookies.has_key?('zssmwy_blog_loginid')
			# no login
			return false
		end

		user_file = './data/users/' + req.cookies['zssmwy_blog_loginid'] + '.json'

		if !File::exist?(user_file)
			# no this user
			return false
		end

		user_data = JSON.parse(File.read(user_file))

		if req.cookies['zssmwy_blog_session'] != user_data['session']
			return false
		end

		return true
	end
end