class AddProgramaUriToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :programa_uri, :string
  end
end
