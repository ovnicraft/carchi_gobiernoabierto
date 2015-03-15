class ChangeQuestionForWhomField < ActiveRecord::Migration
  def self.up
    rename_column :question_datas, :for_whom, :for_whom_id
  end

  def self.down
    rename_column :question_datas, :for_whom_id, :for_whom
  end
end