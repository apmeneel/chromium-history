class BugComment < ActiveRecord::Base
  belongs_to  :bug
  
  def self.optimize
    connection.add_index :bug_comments, :bug_id
    connection.add_index :bug_comments, :author_email
    connection.add_index :bug_comments, :author_uri
    connection.add_index :bug_comments, :updated
    connection.execute "CLUSTER bug_comments USING index_bug_comments_on_bug_id"
  end
 
end
