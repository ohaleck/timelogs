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

class Entry < ActiveRecord::Base
  TOGGL_GUID = 'toggl_id'
  TAG_REGEX = /\(#{TOGGL_GUID}:?\s?([0-9a-f]+)\)/

  #                 2013-09-01T10:30:18.932+0530
  JIRA_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%L%z"

  def guid_int
    guid.to_i(16)
  end

  # duration     : time entry duration in seconds. If the time entry is currently running,
  #                the duration attribute contains a negative value,
  #                denoting the start of the time entry in seconds since epoch (Jan 1 1970).
  #                The correct duration can be calculated as current_time + duration,
  #                where current_time is the current time in seconds since epoch. (integer, required)
  # (from TimeEntries#create_time_entry doc)
  def duration=(d)
    if d < 0
      super(Time.now.to_i + d)
      write_attribute :in_progress, true
    else
      super(d)
    end
  end

  def description=(d)
    if d =~ /\A((\w{1,10})-\d+)\s*(.*)/
      write_attribute :jira_id, $1
      write_attribute :jira_project_id, $2
      write_attribute :description, $3
    else
      super(d)
    end
  end

  def full_description
    if jira_id.present?
      "#{jira_id} #{description}"
    else
      description
    end
  end

  def tag
    "(#{TOGGL_GUID}: #{guid})"
  end

  def jira_formatted_start
    jira_format(start)
  end

  def jira_formatted_stop
    jira_format(stop)
  end

  def to_h
    {
        comment: "#{description}\n#{tag}",
        started: jira_formatted_start,
        timeSpentSeconds: duration,
    }
  end

  private
  def jira_format(time)
    time.strftime(JIRA_TIME_FORMAT)
  end
end
