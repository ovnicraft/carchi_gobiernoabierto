class CreateQuestionDatas < ActiveRecord::Migration
  def self.up
    rename_table :proposals, :contributions
    execute 'ALTER INDEX proposals_pkey RENAME to contributions_pkey'
    execute 'ALTER INDEX proposal_status_idx RENAME to contribution_status_idx'
    rename_table :proposals_id_seq, :contributions_id_seq
    
    add_column :contributions, :type, :string
    Contribution.update_all("type='Proposal'")
    
    Tagging.update_all("taggable_type ='Contribution'", "taggable_type='Proposal'")
    
    create_table :question_datas do |t|
      t.references :question, :null => false
      t.text :answer
      t.integer :for_whom
      t.integer :answered_by
      t.datetime :answered_at
      t.timestamps
    end
    
    execute 'ALTER TABLE question_datas ADD CONSTRAINT fk_qd_question_id FOREIGN KEY (question_id) REFERENCES contributions(id)'
    execute 'ALTER TABLE question_datas ADD CONSTRAINT fk_qd_for_whom FOREIGN KEY (for_whom) REFERENCES users(id)'
    execute 'ALTER TABLE question_datas ADD CONSTRAINT fk_qd_answered_by FOREIGN KEY (answered_by) REFERENCES users(id)'
  end

  def self.down
    remove_column :contributions, :type
    rename_table :contributions_id_seq, :proposals_id_seq
    rename_table :contributions, :proposals
    drop_table :question_datas
  end
end