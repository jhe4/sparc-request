class RemoveParentIdFromOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :lft, :integer
    add_column :organizations, :rgt, :integer

    # convert from adjancency table to modified pre-order
    left = 1
    Organization.where(parent_id: nil).each do |parent|
      left = migrateChildren(parent, left)
    end
  end

  private

  def self.migrateChildren(parent, left)
    right = left + 1

    Organization.where(parent_id: parent.id).order(:order).each do |child|
      right = migrateChildren(child, right)
    end

    parent.update_attributes(lft: left, rgt: right)

    right + 1
  end
end
