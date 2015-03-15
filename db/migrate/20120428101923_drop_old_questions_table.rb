class DropOldQuestionsTable < ActiveRecord::Migration
  def self.up
    drop_table :questions
    drop_table :answers
    execute 'DROP SEQUENCE answers_id_seq'
    execute 'DROP SEQUENCE questions_id_seq'
  end

  def self.down
  end
end
