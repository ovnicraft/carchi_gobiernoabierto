class AddTagKindAndKindInfo < ActiveRecord::Migration
  def self.up
    add_column :tags, :kind, :string
    add_column :tags, :kind_info, :string

    execute "UPDATE tags SET kind='Genérico'"
  end

  def self.down
    remove_column :tags, :kind_info
    remove_column :tags, :kind
  end
end
