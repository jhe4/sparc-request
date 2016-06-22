namespace :data do
  desc "Reconfigure organization structure"

  task reconfigure_organization_structure: :environment do |t, args|
    # OVERVIEW:
   
    # Organizations 49 and 72 are to be combined into one Organization 
    # Organizations 55 & 56 are to remain as type Program
    # Organization 67 is going to be moved under 56 and switched to type Core
    # Organizations 66 is going to be moved under 55 and switched to type Core
    # All the services associated with 73,74,75,76,50,51,52, and 53 will be associated with the new org MUHA Lab
    puts "Reconfiguring structure for orgs 55 & 56"

    TABLES_WITH_ORG_FOREIGN_KEY = [Service, ServiceProvider, Appointment, 
                                  AvailableStatus, CatalogManager, ClinicalProvider, 
                                  PricingSetup, SubServiceRequest, SubmissionEmail, 
                                  SubsidyMap, SuperUser]
    
    # Grab all org_id foreign key tables for 73,74,75,76,50,51,52, and 53 and associate them with Organization 72 "MUHA LAB"
    soon_to_be_deleted_cores = [73,74,75,76,50,51,52,53]
    TABLES_WITH_ORG_FOREIGN_KEY.map do |table|
      if !table.where(organization_id: soon_to_be_deleted_cores).empty?
        puts "Updated table for cores:"
        puts table
        table.where(organization_id: soon_to_be_deleted_cores).each { |row| row.update_attribute(:organization_id, 72) }
      end
    end

    # Grab foreign key tables for 49 and place them under 72
    TABLES_WITH_ORG_FOREIGN_KEY.map do |table|
      if !table.where(organization_id: 49).empty?
        puts "Updated table for org 49:"
        puts table
        table.where(organization_id: 49).each { |row| row.update_attribute(:organization_id, 72) }
      end
    end

    # Organization 72 is going to be moved under 55 and switched to type Core
    Organization.find(72).update_attribute(:type, "Core")
    Organization.find(72).update_attribute(:parent_id, 55)

    # Organizations 66 is going to be moved under 55 and switched to type Core
    Organization.find(66).update_attribute(:type, "Core")
    Organization.find(66).update_attribute(:parent_id, 55)

    # Organization 67 is going to be moved under 56 and switched to type Core
    Organization.find(67).update_attribute(:type, "Core")
    Organization.find(67).update_attribute(:parent_id, 56)

    # CLEAN UP
    # Delete core organizations 73,74,75,76,50,51,52,53 and program organization 49
    organizations_to_be_destroyed = [73,74,75,76,50,51,52,53,49]
    Organization.where(id: organizations_to_be_destroyed).each { |org| org.destroy }

    # ssr_66 = Service.where(organization_id: 66).map(&:line_items).flatten.map(&:sub_service_request_id)
    # ssr_67 = Service.where(organization_id: 67).map(&:line_items).flatten.map(&:sub_service_request_id)
  end
end