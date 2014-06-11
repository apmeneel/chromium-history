# For each file in a given release, populate the necessary metrics
class ReleaseAnalysis

  def populate
    r = Release.find_by(name: '11.0') #hard-coded to Release 11 for now
    r.release_filepaths.find_each do |rf|
      rf.vulnerable = rf.filepath.vulnerable?(r.date)
      rf.num_reviewers = rf.filepath.reviewers.size
      rf.save 
    end
  end

end