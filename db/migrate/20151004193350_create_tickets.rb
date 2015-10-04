class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.integer :project_id
      t.integer :user_id
      t.string :subject
      t.text :content
      t.string :status

      t.timestamps
    end
  end
end
