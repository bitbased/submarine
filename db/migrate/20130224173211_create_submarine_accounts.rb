class CreateSubmarineAccounts < ActiveRecord::Migration
  def change
    create_table :submarine_accounts do |t|

      t.string :subdomain
      t.text :domains
      t.string :domain1
      t.string :domain2
      t.string :domain3
      t.string :domain4
      t.string :domain5

      t.string :account_email
      t.string :account_name
      
      t.text :logo_url
      t.text :small_logo_url

      t.text :api_key
      t.text :api_secret

      t.text :config

      t.boolean :active, :default => true

      t.text :notes
      t.text :history
      t.boolean :visible
      t.datetime :change_time
      t.datetime :deleted_at
      t.text :data
      t.string :resource_type
      t.integer :resource_id
      t.text :resource_name
      t.text :resource_data
      t.text :resource_state

      t.timestamps
    end
    add_index :submarine_accounts, :domain1
    add_index :submarine_accounts, :domain2
    add_index :submarine_accounts, :domain3
    add_index :submarine_accounts, :domain4
    add_index :submarine_accounts, :domain5
  end
end
