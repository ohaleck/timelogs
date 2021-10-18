# == Schema Information
#
# Table name: entries
#
#  id              :integer          not null, primary key
#  description     :string
#  guid            :string
#  wid             :integer
#  pid             :integer
#  start           :datetime
#  stop            :datetime
#  duration        :integer
#  created_with    :string
#  tags            :string
#  duronly         :boolean
#  in_progress     :boolean          default(FALSE), not null
#  jira_id         :string
#  jira_project_id :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
