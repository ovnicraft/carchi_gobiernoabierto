class CreateProposalDatas < ActiveRecord::Migration
  def self.up
    create_table :proposal_datas do |t|
      t.references :proposal, :null => false
      t.string :image
      t.timestamps
    end
        
    execute 'ALTER TABLE proposal_datas ADD CONSTRAINT fk_proposal_data_proposal_id FOREIGN KEY (proposal_id) REFERENCES contributions(id)'
    
    # remove_column :contributions, :photo_file_name
    # remove_column :contributions, :photo_content_type
    # remove_column :contributions, :photo_file_size
    # remove_column :contributions, :photo_updated_at
  end

  def self.down
    drop_table :proposal_datas
    # add_column :contributions, :photo_updated_at, :datetime
    # add_column :contributions, :photo_file_size, :integer
    # add_column :contributions, :photo_content_type, :string
    # add_column :contributions, :photo_file_name, :string
  end
end
