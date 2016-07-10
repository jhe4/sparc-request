class AddIdToDocumentsSubServiceRequests < ActiveRecord::Migration
  def up
    add_column :documents_sub_service_requests, :id, :primary_key
  end

  def down
    remove_column :documents_sub_service_requests, :id
  end
end
