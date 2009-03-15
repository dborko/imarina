require 'active_record'

module Foo
  module Acts #:nodoc:
    module FilePlugin #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_file(storage_path)
          file_env = RAILS_ENV == 'production' ? '' : ('.' + RAILS_ENV)
          class_eval <<-END
            CONTENT_TYPES = {
              'gif' => "image/gif",
              'jpg' => "image/jpeg",
              'png' => "image/png",
              'swf' => "application/x-shockwave-flash",
              'pdf' => "application/pdf",
              'doc' => "application/msword",
              'zip' => "application/zip",
              'mp3' => "audio/mpeg",
              'wma' => "audio/x-ms-wma",
              'wav' => "audio/x-wav",
              'css' => "text/css",
              'html' => "text/html",
              'js' => "text/javascript",
              'txt' => "text/plain",
              'xml' => "text/xml",
              'mpeg' => "video/mpeg",
              'mpg' => "video/mpeg",
              'mov' => "video/quicktime",
              'avi' => "video/x-msvideo",
              'asf' => "video/x-ms-asf",
              'wmv' => "video/x-ms-wmv"
            }
          
            def has_file?
              !file_path.nil?
            end
            
            def file_name
              return nil unless id
              matches = Dir[File.join('#{storage_path}', id.to_s + '#{file_env}.*')].select { |p| p.index('#{file_env}') }.map { |p| File.split(p).last }
              matches.any? ? matches.first : nil
            end
            
            def file_path
              file_name ? File.join('#{storage_path}', file_name) : nil
            end
            
            def base_file_path
              return nil unless id
              File.join('#{storage_path}', id.to_s + '#{file_env}')
            end
            
            def file_content_type
              file_name ? CONTENT_TYPES[file_name.split('.').last] : nil
            end
            
            def file_size
              @file_size ||= File::Stat.new(file_path).size
            end
            
            def file=(file)
              raise 'Cannot save file before saving record.' unless id
              File.delete file_path if file_path
              if file
                filename = file.original_filename
                file = file.read
                output_path = File.join('#{storage_path}', id.to_s + '#{file_env}.' + filename.split('.').last.downcase)
                File.open(output_path, 'w') do |f|
                  f.write(file)
                end
              end
            end
            
            def destroy
              self.file = nil
              super
            end
          END
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::FilePlugin
end
