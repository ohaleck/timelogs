class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :description
      t.string :guid
      t.integer :wid
      t.integer :pid
      t.datetime :start
      t.datetime :stop
      t.integer :duration
      t.string :created_with
      t.string :tags
      t.boolean :duronly
      t.boolean :in_progress, null: false, default: false
      t.string :jira_id
      t.string :jira_project_id
      t.timestamps null: false
    end
  end
end
