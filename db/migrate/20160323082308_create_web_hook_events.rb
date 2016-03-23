class CreateWebHookEvents < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'

    create_table :web_hook_events, id: :uuid do |t|
      t.string :url, null: false
      t.string :type, null: false # a single type
      t.integer :web_hook_id
      t.integer :status
      t.integer :retries, default: 0
      t.string :request_header
      t.string :request_payload
      t.integer :response_code
      t.string :response_header
      t.string :response_payload
      t.integer :completion_time

      t.timestamps null: false
    end
  end
end
