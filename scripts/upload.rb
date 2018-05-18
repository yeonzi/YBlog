# -*- encoding: utf-8 -*-
# upload.rb - v1

require 'digest/sha1'
require 'json'

class Upload
	def self.call(env)
		req = Rack::Request.new(env)
		if req.post?
			if !SimpleAuth.pass?(req)
				return_content = Hash.new
				return_content['success'] = 0
				return_content['message'] = 'Login requested'
				return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
			else
				upload_file = req.POST['editormd-image-file'][:tempfile].read
				upload_sha1 = Digest::SHA1.hexdigest(upload_file).upcase
				upload_ext  = req.POST['editormd-image-file'][:filename][/\.[^\.]+$/]
	
				saved_file_name = './data/image/' + upload_sha1 + upload_ext
	
				saved_file = File.new(saved_file_name, "wb")
				saved_file.write(upload_file)
				saved_file.close
	
				puts saved_file_name + ' Saved.'
				return_content = Hash.new
				return_content['success'] = 1
				return_content['message'] = 'Upload Success'
				return_content['url'] = './image/' + upload_sha1 + upload_ext
				return ['200', {'Content-Type' => 'application/json'}, [return_content.to_json]]
			end
		else
			return ['404', {'Content-Type' => 'text/html'}, ['']]
		end
	end
end