class RemoveProgramaUriFromAreas < ActiveRecord::Migration
  def change
    remove_column :areas, :programa_uri
  end
end
