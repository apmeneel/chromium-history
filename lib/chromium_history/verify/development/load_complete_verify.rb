require_relative "../verify_base"

class LoadCompleteVerify < VerifyBase

  def verify_exactly_4_code_reviews_exist
    count = CodeReview.count
    if count > 4
      fail("More than 4 code_reviews found.")
    elsif count < 4
      fail("Less than 4 code_reviews found.")
    else
      pass()
    end
  end

  def verify_exactly_12_patch_sets_exist
    count = PatchSet.count
    if count > 12
      fail("More than 12 patch_sets found.")
    elsif count < 12
      fail("Less than 12 patch_sets found.")
    else
      pass()
    end
  end

  def verify_exactly_9_comments_exist
    count = Comment.count
    if count > 9
      fail("More than 9 comments found.")
    elsif count < 9
      fail("Less than 9 comments found.")
    else
      pass()
    end
  end

  def verify_code_review_10854242_has_23_messages
    helper_count_messages(10854242, 23)
  end

  def verify_code_review_23444043_has_16_messages
    helper_count_messages(23444043, 16)
  end

  def verify_code_review_5754053585797120_has_9_messages
    helper_count_messages(5754053585797120, 9)
  end

  def verify_code_review_9141024_has_2_messages
    helper_count_messages(9141024, 2)
  end

  def verify_code_review_9141024_was_loaded
    helper_code_review_was_loaded(9141024)
  end

  def verify_code_review_10854242_was_loaded
    helper_code_review_was_loaded(10854242)
  end

  def verify_code_review_23444043_was_loaded
    helper_code_review_was_loaded(23444043)
  end

  def verify_code_review_5754053585797120_was_loaded
    helper_code_review_was_loaded(5754053585797120)
  end

  private
  def helper_code_review_was_loaded(issue)
    count = CodeReview.where(issue: issue).count
    if count > 1
      fail("Code review #{issue} is duplicate.")
    elsif count < 1
      fail("Code review #{issue} not found.")
    else
      pass()
    end
  end

  def helper_count_messages(code_review, expected)
    count = CodeReview.where(issue: code_review).first.messages.count
    if count > expected
      fail("More than #{expected} messages found.")
    elsif count < expected
      fail("Less than #{expected} messages found.")
    else
      pass()
    end
  end

end