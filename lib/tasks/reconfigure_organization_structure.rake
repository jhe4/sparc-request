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
    AUDIT_COMMENT = "reconfigure_organization_structure"

    ActiveRecord::Base.transaction do
      # Grab all org_id foreign key tables for Cores 73,74,75,76,50,51,52,53 and Program 49 and associate them with Organization 72 "MUHA LAB"
      soon_to_be_deleted_orgs = [73,74,75,76,50,51,52,53, 49]
      TABLES_WITH_ORG_FOREIGN_KEY.map do |table|
        table.where(organization_id: soon_to_be_deleted_orgs).each { |row| row.update_attribute(:organization_id, 72) }
      end

      # Organization 72 is going to be moved under 55 and switched to type Core
      Organization.find(72).update!(type: "Core", audit_comment: AUDIT_COMMENT)
      Organization.find(72).update!(parent_id: 55, audit_comment: AUDIT_COMMENT)

      # Organizations 66 is going to be moved under 55 and switched to type Core
      Organization.find(66).update!(type: "Core", audit_comment: AUDIT_COMMENT)
      Organization.find(66).update!(parent_id: 55, audit_comment: AUDIT_COMMENT)

      # Organization 67 is going to be moved under 56 and switched to type Core
      Organization.find(67).update!(type: "Core", audit_comment: AUDIT_COMMENT)
      Organization.find(67).update!(parent_id: 56, audit_comment: AUDIT_COMMENT)

      # CLEAN UP
      # Delete core organizations 73,74,75,76,50,51,52,53 and program organization 49
      organizations_to_be_destroyed = [73,74,75,76,50,51,52,53,49]
      Organization.where(id: organizations_to_be_destroyed).each do |org|
        org.destroy
        org.audits.last.update!(comment: AUDIT_COMMENT)
      end

      # TEASE APART SubServiceRequests
      # Sub Service Requests that are shared by the line items associated with org 66 and org 67
      ssrs_to_split = SubServiceRequest.joins(:services).where(services: { organization_id: 66 }) &
         SubServiceRequest.joins(:services).where(services: { organization_id: 67 })
      # When splitting SSR's, the SSR containing 66's services will have this organization_id:
      process_ssrs_66 = Organization.find(66).process_ssrs_parent.id
      # When splitting SSR's, the SSR containing 67's services will have this organization_id:
      process_ssrs_67 = Organization.find(67).process_ssrs_parent.id

      ssrs_to_split_count = ssrs_to_split.count
      ssrs_to_split_so_far = 0
      puts "Splitting SSRs"
      ssrs_to_split.each do |ssr|
        ssrs_to_split_so_far += 1
        puts "#{ssrs_to_split_so_far}/#{ssrs_to_split_count}"

        ssr_66 = ssr.service_request.sub_service_requests.where(organization_id: process_ssrs_66).first
        ssr_67 = ssr.service_request.sub_service_requests.where(organization_id: process_ssrs_67).first

        # determine who will have 66's services and who'll have 67's
        if ssr_66.nil? && ssr_67.nil?
          ssr_66 = mimic_ssr(ssr)
          ssr_67 = ssr
        elsif ssr_66.nil?
          ssr_66 = ssr
        elsif ssr_67.nil?
          ssr_67 = ssr
        end

        # make sure organization_id's are correct
        ssr_66.update!(organization_id: process_ssrs_66, audit_comment: AUDIT_COMMENT)
        ssr_67.update!(organization_id: process_ssrs_67, audit_comment: AUDIT_COMMENT)

        # make sure LineItems are in the proper place
        ssr_mapping = { 66 => ssr_66.id, 67 => ssr_67.id }
        LineItem.where(sub_service_request_id: [ssr_66.id, ssr_67.id, ssr.id]).each do |li|
          li.update!(sub_service_request_id: ssr_mapping[li.service.organization_id], audit_comment: AUDIT_COMMENT)
        end

        # destroy ssr if we emptied it
        sr = ssr.service_request
        if ssr.reload.line_items.empty?
          dup_relationships(ssr, ssr_66)
          dup_relationships(ssr, ssr_67)

          ssr.destroy()
          ssr.audits.last.update(comment: AUDIT_COMMENT)
        end

        # update next_ssr_id on ServiceRequest and set ssr_id's on new SSR's
        unless sr.nil? || sr.protocol_id.nil?
          sr.try(:ensure_ssr_ids) # some SSR's have no SR
        end
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

  # duplicate SSR, and copy over some relationships from the original to the
  # duplicate
  def mimic_ssr(orig_ssr)
    mimic = orig_ssr.dup

    # take care of ssr_id later with service_request.ensure_ssr_ids
    mimic.update!(audit_comment: AUDIT_COMMENT, ssr_id: nil)

    dup_relationships(orig_ssr, mimic)

    mimic
  end

  # copy over documents, approvals, notifications, past statuses
  def dup_relationships(from_ssr, to_ssr)
    # copy over has_* relationships to other SubServiceRequest
    blindly_copy_over = [:approvals, :notifications, :past_statuses]
    blindly_copy_over.each do |child_name|
      dup_children_objs(from_ssr, to_ssr, child_name)
    end

    # copy over Documents
    from_ssr.documents.each do |document|
      DocumentsSubServiceRequest.create!(sub_service_request_id: to_ssr.id, document_id: document.id, audit_comment: AUDIT_COMMENT)
    end
  end

  # copy over has_many relationship
  def dup_children_objs(from_ssr, to_ssr, child_name)
    from_ssr.send(child_name).each do |child|
      child_dup = child.dup
      child_dup.update!(sub_service_request_id: to_ssr.id, audit_comment: AUDIT_COMMENT)
    end
  end
end
