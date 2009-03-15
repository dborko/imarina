require 'yaml'

namespace :onebody do
  task :build_settings_fixture_file => :environment do
    flat_settings = {}

    YAML::load_file(RAILS_ROOT + '/config/settings.yml').each do |section_name, section|
      section.each do |setting_name, setting|
        setting['section'] = section_name
        setting['name'] = setting_name
        setting['site_id'] = 1 unless setting['global']
        flat_settings["#{section_name}_#{setting_name}".downcase.scan(/[a-z_]+/).join] = setting
      end
    end

    File.open(RAILS_ROOT + '/test/fixtures/settings.yml', 'w') do |file|
      YAML::dump(flat_settings, file)
    end
  end
end
