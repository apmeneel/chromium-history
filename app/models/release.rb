class Release < ActiveRecord::Base

  has_many :release_filepaths, primary_key: 'name', foreign_key: 'release'

  def self.on_optimize
    ActiveRecord::Base.connection.add_index :releases, :name, unique: true
  end

end

