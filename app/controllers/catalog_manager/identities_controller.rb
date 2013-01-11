class CatalogManager::IdentitiesController < CatalogManager::AppController
  require 'search'
  respond_to :json
  layout false

  def associate_with_org_unit
    org_unit_id = params["org_unit"]
    identity_id = params["identity"]
    rel_type = params["rel_type"]

    #oe = ObisEntity.find org_unit_id
    oe = Organization.find org_unit_id
    identity = Identity.find identity_id

    if rel_type == 'service_provider_organizational_unit'
      if not oe.service_providers or (oe.service_providers and not oe.service_providers.map(&:id).include? identity_id)
        # we have a new relationship to create
        #identity.create_relationship_to oe.id, 'service_provider_organizational_unit', {"view_draft_status" => false, "is_primary_contact" => false, "hold_emails" => false}
        service_provider = oe.service_providers.new
        service_provider.identity = identity
        service_provider.save
      end

      render :partial => 'catalog_manager/shared/service_providers', :locals => {:entity => oe}

    elsif rel_type == 'super_user_organizational_unit'
      if not oe.super_users or (oe.super_users and not oe.super_users.map(&:id).include? identity_id)
        # we have a new relationship to create
        #identity.create_relationship_to oe.id, 'super_user_organizational_unit'
        super_user = oe.super_users.new
        super_user.identity = identity
        super_user.save
      end

      render :partial => 'catalog_manager/shared/super_users', :locals => {:entity => oe}
    elsif rel_type == 'catalog_manager_organizational_unit'
      if not oe.catalog_managers or (oe.catalog_managers and not oe.catalog_managers.map(&:id).include? identity_id)
        # we have a new relationship to create
        #identity.create_relationship_to oe.id, 'catalog_manager_organizational_unit'
        catalog_manager = oe.catalog_managers.new
        catalog_manager.identity = identity
        catalog_manager.save
      end

      render :partial => 'catalog_manager/shared/catalog_managers', :locals => {:entity => oe}
    end
  end

  def disassociate_with_org_unit
    rel_type = params["rel_type"]
    relationship = params["relationship"]

    oe = Organization.find params["org_unit"]

    if rel_type == 'service_provider_organizational_unit'
      service_provider = ServiceProvider.find params["relationship"]
      service_provider.destroy
      render :partial => 'catalog_manager/shared/service_providers', :locals => {:entity => oe}
    elsif rel_type == 'super_user_organizational_unit'
      super_user = SuperUser.find params["relationship"]
      super_user.destroy
      render :partial => 'catalog_manager/shared/super_users', :locals => {:entity => oe}
    elsif rel_type == 'catalog_manager_organizational_unit'
      catalog_manager = CatalogManager.find params["relationship"]
      catalog_manager.destroy
      render :partial => 'catalog_manager/shared/catalog_managers', :locals => {:entity => oe}
    end
  end

  ########Not addressed yet, doesn't appear in coffescript/js########
  def set_view_draft_status
    rel_id       = params["rel_id"]
    status_flag  = params["status_flag"] == "true"
    contact_flag = params["contact_flag"] == "true"
    emails_flag  = params["emails_flag"] == "true"

    atts = {:view_draft_status => status_flag == false, :is_primary_contact => contact_flag, :hold_emails => emails_flag}

    @rel = {
      'relationship_type' => 'service_provider_organizational_unit',
      'attributes'        => atts,
      'from'              => params["identity"],
      'to'                => params["org_id"]
    }

    identity = Identity.find params["identity"]
    oe = ObisEntity.find params["org_id"]

    identity.update_relationship rel_id, @rel

    render :partial => 'catalog_manager/shared/service_providers', :locals => {:entity => oe}
  end

  def set_primary_contact
    service_provider = ServiceProvider.find params["service_provider"]
    oe = Organization.find params["org_id"]

    #Toggle
    if service_provider.is_primary_contact
      service_provider.is_primary_contact = false
    else
      service_provider.is_primary_contact = true
    end

    service_provider.save

    render :partial => 'catalog_manager/shared/service_providers', :locals => {:entity => oe}
  end

  def set_hold_emails
    service_provider = ServiceProvider.find params["service_provider"]
    oe = Organization.find params["org_id"]

    #Toggle
    if service_provider.hold_emails
      service_provider.hold_emails = false
    else
      service_provider.hold_emails = true
    end

    service_provider.save

    render :partial => 'catalog_manager/shared/service_providers', :locals => {:entity => oe}
  end

  def set_edit_historic_data
    manager = CatalogManager.find params["manager"]
    oe = Organization.find params["org_id"]

    #Toggle
    if manager.edit_historic_data
      manager.edit_historic_data = false
    else
      manager.edit_historic_data = true
    end

    manager.save
    
    render :partial => 'catalog_manager/shared/catalog_managers', :locals => {:entity => oe}
  end

  def search
    term = params[:term].strip
    results = Identity.search(term).map do |i| 
      {
       :label => i.display_name, :value => i.id, :email => i.email, :institution => i.institution, :phone => i.phone, :era_commons_name => i.era_commons_name,
       :college => i.college, :department => i.department, :credentials => i.credentials, :credentials_other => i.credentials_other
      }
    end
    results = [{:label => 'No Results'}] if results.empty?
    render :json => results.to_json
  end
end
