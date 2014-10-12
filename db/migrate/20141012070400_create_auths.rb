class CreateAuths < ActiveRecord::Migration
  def up
    create_table :auths do |t|
      t.string :username
      t.string :password
      t.string :key

      t.timestamps
    end
  end

  def down
    drop_table :auths
  end
end
