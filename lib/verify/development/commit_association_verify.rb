require_relative '../verify_base'

class CommitAssociationVerify < VerifyBase
  def verify_reviewers_for_6eebdee
    assert_equal 3, Commit.where(commit_hash: '6eebdee7851c52b1f481fca1cdffcbc51c8ec061').take.reviewers.count
    assert_equal ['danakj@chromium.org','ojan@chromium.org','skaslev@chromium.org'], Commit.where(commit_hash: '6eebdee7851c52b1f481fca1cdffcbc51c8ec061').take.reviewers.pluck(:email).to_a.sort

  end

  def verify_commit_filepath_to_cve
    assert_equal true, CommitFilepath.where(filepath: 'ui/base/x/x11_util.cc').take.cve?
  end

end
