class ConvertQuestionsIntoProposals < ActiveRecord::Migration
  def self.up
    execute "UPDATE contributions SET type='Proposal' WHERE type='Question'"
    add_column :comments, :is_answer, :boolean, :null => false, :default => false
    Comment.update_all("is_answer='f'")
    answers = Comment.find_by_sql("SELECT id, question_id, body, answered_by, answered_at, created_at, updated_at from answers order by id")
    answers.each do |answer|
      user = User.find(answer.answered_by)
      proposal = Proposal.find(answer.question_id)
      comment = proposal.comments.build :name => user.public_name, :email => user.email,
                            :body => answer.body, :status => 'aprobado', 
                            :created_at => answer.answered_at, :updated_at => answer.updated_at,
                            :user_id => answer.answered_by, :is_official => true,
                            :is_answer => true
      if comment.save
        puts "http://#{ActionMailer::Base.default_url_options[:host]}/es/proposals/#{proposal.id}
Traspasada la respuesta #{answer.id} (#{answer.answered_at}) al comentario #{comment.id} (#{comment.created_at})
---"
      else
        puts "No se ha guardado el comentario para la respuesta #{answer.id}: #{comment.errors.inspect}"
      end
      proposal.update_elasticsearch_server
    end
  end

  def self.down
    remove_column :comments, :is_answer
  end
end