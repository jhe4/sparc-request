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

    # Grab all org_id foreign key tables for Cores 73,74,75,76,50,51,52,53 and Program 49 and associate them with Organization 72 "MUHA LAB"
    soon_to_be_deleted_orgs = [73,74,75,76,50,51,52,53, 49]
    TABLES_WITH_ORG_FOREIGN_KEY.map do |table|
      table.where(organization_id: soon_to_be_deleted_orgs).each { |row| row.update_attribute(:organization_id, 72) }
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

    # TEASE APART SubServiceRequests
    # Sub Service Requests that are shared by the line items associated with org 66 and org 67
    split_ssrs = Service.where(organization_id: 66).map(&:line_items).flatten.map(&:sub_service_request_id) &
      Service.where(organization_id: 67).map(&:line_items).flatten.map(&:sub_service_request_id)

    # When splitting SSR's, the SSR containing 66's services will have this organization_id:
    process_ssrs_66 = Organization.find(66).process_ssrs_parent.id
    # When splitting SSR's, the SSR containing 67's services will have this organization_id:
    process_ssrs_67 = Organization.find(67).process_ssrs_parent.id

    split_ssrs.each do |ssr|
      # Arbitrarily pick this ssr to hold 66's services;
      # new SSR will hold 67's
      ssr.update_attribute(:organization_id, process_ssrs_66)

      # build SSR for 67's serivces
      new_ssr = SubServiceRequest.create() # I guess use some atttributes from ssr
      # possibly use new_ssr.create_line_item() to move line items over
      # also consider modifying related:
        # approvals
        # cover_letters
        # documents_sub_service_requests
        # notifications
        # past_statuses
        # payments
        # reports
        # response_sets
        # subsidies
      ssr.service_request.ensure_ssr_ids
      ssr.update_org_tree
    end
  end
end
