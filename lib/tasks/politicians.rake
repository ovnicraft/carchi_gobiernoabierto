# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')

namespace 'irekia_politicians' do
  desc "Comporbar la consistencia de los datos"
  task :check_data => [:environment] do
    Politician.approved.each do |politician|
      if !politician.areas.present?
        puts "Político sin área: #{politician.public_name} (#{politician.id})"
      end
      if !politician.department.present?
        puts "Político sin departamento: #{politician.public_name} (#{politician.id})"
      end
      if !politician.tag.present?
        puts "Político sin tag: #{politician.public_name} (#{politician.id})"
      end
      if !politician.gc_id.present?
        puts "Político sin enlace a la Guía: #{politician.public_name} (#{politician.id})"
      end
    end
  end
end