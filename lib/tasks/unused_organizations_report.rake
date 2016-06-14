namespace :data do
  desc "Generate a CSV of non-parent Organizations not associated with services or sub service requests"

  task unused_organizations_report: :environment do
    CSV.open("tmp/unused_organizations_report.csv", "w+") do |csv|
      csv << ["Org ID", "Organization Name", "Organization Type"]

      all_orgs = Organization.all.map(&:id)

      used_orgs = [
                  Appointment.all.map(&:organization_id),
                  Service.all.map(&:organization_id),
                  SubServiceRequest.all.map(&:organization_id),
                  ].flatten.uniq

      unused_orgs_with_unknown_parent_status = all_orgs - used_orgs
      unused_orgs = []

      unused_orgs_with_unknown_parent_status.each do |unused_org|
        if Organization.find(unused_org).org_children.count.zero?
          unused_orgs << unused_org
        end
      end

      # report rows
      report_data = unused_orgs.map do |org|
        csv << [org, Organization.find(org).name, Organization.find(org).type]
      end
    end
  end
end