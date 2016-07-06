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

    ActiveRecord::Base.transaction do
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
      split_ssrs = SubServiceRequest.joins(:services).where(services: { organization_id: 66 }) &
         SubServiceRequest.joins(:services).where(services: { organization_id: 67 })
      # When splitting SSR's, the SSR containing 66's services will have this organization_id:
      process_ssrs_66 = Organization.find(66).process_ssrs_parent.id
      # When splitting SSR's, the SSR containing 67's services will have this organization_id:
      process_ssrs_67 = Organization.find(67).process_ssrs_parent.id

      split_ssrs_count = split_ssrs.count
      split_ssrs_so_far = 0
      puts "Splitting SSRs"
      split_ssrs.each do |ssr|
        split_ssrs_so_far += 1
        puts "#{split_ssrs_so_far}/#{split_ssrs_count}"
        # new SSR for 66's serivces
        new_ssr = ssr.dup
        new_ssr.organization_id = process_ssrs_66
        new_ssr.save!

        # use original for 67's services
        ssr.update_attribute(:organization_id, process_ssrs_67)

        ssr.line_items.joins(:service).where(services: { organization_id: 66 }).each do |li|
          li.update_attribute(:sub_service_request_id, new_ssr.id)

          # ...
          li.destroy
        end

        # has_* relationships to copy over to the new SubServiceRequest
        # Only thing that changes on the duplicates is the sub_service_request_id...
        # Remarks:
        #   * Is CoverLetter being used anymore?  NO
        #   * What do we do about Payments? Not used any more
        #   * What to do about Reports? Can we update them? I would say we need to update them
        #   * Not sure what a ResponseSet is, but it needs to be dealt with.  They can be updated if they have SubServiceRequest attached
        #   * Same for Subsidies.  They can be updated as well

        blindly_copy_over = [:approvals, :notifications, :past_statuses]

        blindly_copy_over.each do |child_name|
          dup_children_objs(ssr, new_ssr, child_name)
        end

        # copy over Documents
        new_ssr.documents << ssr.documents

        # update next_ssr_id on ServiceRequest
        unless new_ssr.service_request_id.nil? || new_ssr.service_request.protocol_id.nil?
          new_ssr.service_request.try(:ensure_ssr_ids) # some SSR's have no SR
        end

        new_ssr.save!
      end

      # rebuild org_tree for all SubServiceRequests
      # probably unnecessary for EACH, but this'll totally work
      puts "Updating org_tree_displays"
      SubServiceRequest.all.group_by(&:organization_id).each do |organization_id, ssrs|
        next if ssrs.empty?
        ssrs.first.update_org_tree
        updated_org_tree = ssrs.first.org_tree_display
        SubServiceRequest.where(organization_id: organization_id).update_all(org_tree_display: updated_org_tree)
      end
    end
  end

  def dup_children_objs(orig_ssr, new_ssr, child_name)
    orig_ssr.send(child_name).each do |child|
      child_dup = child.dup
      child_dup.sub_service_request_id = new_ssr.id
      child_dup.save!
    end
  end
end
