# Toggl API docs: https://github.com/toggl/toggl_api_docs
# Jira API docs: https://docs.atlassian.com/jira/REST/cloud/#api/2/issue/{issueIdOrKey}/worklog
class TogglJira
  API_KEY = ENV['toggl_api_key']

  JIRA_OPTIONS = {
      :username => ENV['jira_username'],
      :password => ENV['jira_password'],
      :site => ENV['jira_url'],
      :context_path => '',
      :auth_type => :basic,
      :http_debug => true
  }

  THIS_YEAR = DateTime.now.beginning_of_year
  LAST_MONTH = DateTime.now.last_month.beginning_of_month
  THIS_MONTH = DateTime.now.beginning_of_month
  THIS_WEEK = DateTime.now.beginning_of_week
  TODAY = DateTime.now.beginning_of_day
  YESTERDAY = DateTime.now.yesterday.beginning_of_day

  def get
    log.info "Getting entries from Toggl..."
    api = TogglV8::API.new(API_KEY)
    entries = api.get_time_entries(start_date: LAST_MONTH, end_date: YESTERDAY)
    Entry.delete_all
    entries.each do |entry|
      entry.select! {|x| Entry.attribute_names.index(x)}

      Entry.create(entry)
    end
    log.info "Done talking to Toggl."
  end

  def delete
    client = JIRA::Client.new(JIRA_OPTIONS)
    jids_to_entries = {}
    Entry.all.each do |entry|
      jids_to_entries[entry.jira_id] ||= {}
      jids_to_entries[entry.jira_id][entry.guid] = entry
    end

    log.info "Contacting JIRA API..."
    # JQL throws HTTP 400 when no issue can be found by id
    # jql_query = "id IN (#{jids_to_entries.keys.compact.join(', ')})"
    # log.debug jql_query
    # issues_test = client.Issue.jql(jql_query)
    jids_to_entries.each_with_index do |(jid, entries), index|
      log.info "Getting info for issue #{index+1}/#{jids_to_entries.size}..."
      next if jid.nil?
      issue = begin
        client.Issue.find(jid)
      rescue JIRA::HTTPError => e
        if e.response.code.to_s == '404'
          log.error "No Jira Entry for Jira id #{jid}"
          next
        else
          raise e
        end
      end
      worklogs = issue.worklogs
      log.info "Looking for existing worklogs..."
      worklogs.each do |wl|
        comment = wl.attrs.keys.include?('comment') ? wl.comment : ''
        if comment =~ Entry::TAG_REGEX
          toggl_guid = $1
          if entries[toggl_guid].present?
            client.delete('/'+wl.url)
          end
        end
      end
    end
  end

  def log_work
    client = JIRA::Client.new(JIRA_OPTIONS)
    jids_to_entries = {}
    Entry.all.each do |entry|
      jids_to_entries[entry.jira_id] ||= {}
      jids_to_entries[entry.jira_id][entry.guid] = entry
    end

    log.info "Contacting JIRA API..."
    # JQL throws HTTP 400 when no issue can be found by id
    # jql_query = "id IN (#{jids_to_entries.keys.compact.join(', ')})"
    # log.debug jql_query
    # issues_test = client.Issue.jql(jql_query)
    jids_to_entries.each_with_index do |(jid, entries), index|
      log.info "Getting info for issue #{index+1}/#{jids_to_entries.size}..."
      next if jid.nil?
      issue = begin
        client.Issue.find(jid)
      rescue JIRA::HTTPError => e
                if e.response.code.to_s == '404'
                  log.error "No Jira Entry for Jira id #{jid}"
                  next
                else
                  raise e
                end
      end
      worklogs = issue.worklogs
      log.info "Looking for existing worklogs..."
      worklogs.each do |wl|
        comment = wl.attrs.keys.include?('comment') ? wl.comment : ''
        if comment =~ Entry::TAG_REGEX
          toggl_guid = $1
          if entries[toggl_guid].present?
            update_worklog(entries.delete($1), wl)
          end
        end
      end
      log.info "Logging remaining #{entries.size} entries..."
      entries.values.each do |entry|
        add_worklog(entry, issue)
      end
    end
  end

  def add_worklog(toggl_entry, issue)
    worklog = issue.worklogs.build()
    log.info "Creating jira worklog entry for toggl entry #{toggl_entry['jira_id']}"

    do_request(toggl_entry, worklog)
  end

  def update_worklog(toggl_entry, worklog)
    log.info "Updating jira worklog #{worklog.id} with toggl_entry #{toggl_entry['jira_id']}"
    do_request(toggl_entry, worklog)
  end


  def do_request(toggl_entry, worklog)
    begin
      request_data = toggl_entry.to_h
      worklog.save!(request_data)
    rescue JIRA::HTTPError => e
      handle_error e
    end
  end

  def handle_error(e)
    if e.response.is_a?(Net::HTTPBadRequest) && e.response.body.present?
      json_response = JSON.parse(e.response.body)
      log.error 'Bad request'
      if json_response['errors'].present?
        json_response['errors'].each do |key, message|
          log.error "#{key}: #{message}"
        end
      end
    else
      log.error "Error: #{e.message}"
      log.error e.backtrace.join("\n")
    end
  end

  def log
    @log ||= ( Logger.new(STDOUT)) # Rails.logger ||
  end
end
