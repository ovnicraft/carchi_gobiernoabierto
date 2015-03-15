class CreateAnswers < ActiveRecord::Migration
  def self.up
    create_table :answers do |t|
      t.references :question, :null => false
      t.text :body
      t.string :video_title
      t.text :video_description
      t.string :youtube_url
      t.string :vimeo_url
      t.string :thumbnail_url
      t.text :video_html
      t.integer :answered_by
      t.datetime :answered_at
      t.timestamps
    end
    
    remove_column :question_datas, :answer
    remove_column :question_datas, :answered_by
    remove_column :question_datas, :answered_at
    
    execute 'ALTER TABLE answers ADD CONSTRAINT fk_answers_question_id FOREIGN KEY (question_id) REFERENCES contributions(id)'
    execute 'ALTER TABLE answers ADD CONSTRAINT fk_answers_answered_by FOREIGN KEY (answered_by) REFERENCES users(id)'
  end

  def self.down
    add_column :question_datas, :answered_at, :datetime
    add_column :question_datas, :answered_by, :integer
    add_column :question_datas, :answer, :text
    drop_table :answers
  end
end
