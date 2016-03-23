class CreateWebHooks < ActiveRecord::Migration
  def change
    create_table :web_hooks do |t|
      t.string :url, null: false
      t.string :type, null: false # an array of type, enum or string?
      t.integer :content_type, null: false, default: 0
      t.string :secret
      t.boolean :verify_tls_certification, null: false, default: true
      t.boolean :active, null: false, default: true

      t.timestamps null: false
    end
  end
end
