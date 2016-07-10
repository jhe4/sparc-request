class DocumentsSubServiceRequest < ActiveRecord::Base
  audited
  attr_accessible :audit_comment
  
  attr_accessible :sub_service_request_id
  attr_accessible :document_id
end
