class AddLftAndRgtToOrganizations < ActiveRecord::Migration
  def up
    add_column :organizations, :lft, :integer
    add_column :organizations, :rgt, :integer

    # convert from adjancency table to modified pre-order
    left = 1
    Organization.where(parent_id: nil).each do |parent|
      left = migrate_children(parent, left)
    end

    remove_column :organizations, :parent_id
  end

  def down
    remove_column :organizations, :lft
    remove_column :organizations, :rgt
  end

  def migrate_children(parent, left)
    right = left + 1

    Organization.where(parent_id: parent.id).order(:order).each do |child|
      right = migrate_children(child, right)
    end

    parent.update_attributes(lft: left, rgt: right)

    right + 1
  end
end
