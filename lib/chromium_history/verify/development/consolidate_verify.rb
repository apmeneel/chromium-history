require_relative "../verify_base"

class ConsolidateVerify < VerifyBase

  def verify_filepath_consolidation_count
    assert_equal(99,Filepath.all.count)
  end

end#end of class