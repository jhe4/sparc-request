namespace :data do
  desc "Reconfigure organization structure"

  task reconfigure_organization_structure: :environment do |t, args|

    # For new MUSC institution structure
    puts "Reconfiguring structure for MUSC"
    new_providers = [8, 157, 146, 40, 43, 58, 130, 22]
    Organization.where(parent_id: 45).where.not(id: new_providers).each { |org| org.update_attribute(:parent_id, nil) }
    Organization.where(id: new_providers).each { |org| org.update_attribute(:parent_id, 45); org.update_attribute(:type, "Provider") }
  end
end