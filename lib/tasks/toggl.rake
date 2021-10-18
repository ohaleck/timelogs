require 'toggl_jira'

namespace :toggl do
  desc "TODO"
  task get: :environment do
    TogglJira.new.get
  end

  task log_work: :environment do
    TogglJira.new.log_work
  end

  task delete: :environment do
    TogglJira.new.delete
  end

  task all: [:environment, :get, :log_work]

end
