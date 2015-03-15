class RemoveExportToEnet < ActiveRecord::Migration
  def change
    drop_table :enet_ejes
    remove_column :organizations, :enet_workarea
    drop_table :enet_export_status
    remove_column :documents, :exported_to_enet_at
    drop_table :tag_eje
  end
end
