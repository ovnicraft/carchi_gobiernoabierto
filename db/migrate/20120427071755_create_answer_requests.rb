class CreateAnswerRequests < ActiveRecord::Migration
  def self.up
    create_table :answer_requests do |t|
      t.references :question_data, :null => false
      t.references :user, :null => false
      t.timestamps
    end
    
    execute 'ALTER TABLE answer_requests ADD CONSTRAINT fk_ar_question_id FOREIGN KEY (question_data_id) REFERENCES question_datas(id)'
    execute 'ALTER TABLE answer_requests ADD CONSTRAINT fk_ar_user_id FOREIGN KEY (user_id) REFERENCES users(id)'
    
    add_column :question_datas, :answer_requests_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :question_datas, :answer_requests_count
    drop_table :answer_requests
  end
end