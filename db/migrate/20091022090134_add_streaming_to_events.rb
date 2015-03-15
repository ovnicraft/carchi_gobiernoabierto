class AddStreamingToEvents < ActiveRecord::Migration
  def self.up
    add_column :documents, :stream_flow_id, :integer
  end

  def self.down
    remove_column :documents, :irekia_coverage_streaming
  end
end
