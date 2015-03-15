class CreateEnetExportStatus < ActiveRecord::Migration
  def self.up
    create_table :enet_export_status do |t|
      t.datetime :last_exported_at
      t.timestamps
    end
    Enet::ExportStatus.create(:last_exported_at => 1.month.ago)
  end

  def self.down
    drop_table :enet_export_status
  end
end
