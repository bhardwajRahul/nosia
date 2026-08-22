class AddStoppedAtToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :stopped_at, :datetime
  end
end
