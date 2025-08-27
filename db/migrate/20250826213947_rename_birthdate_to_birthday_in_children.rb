class RenameBirthdateToBirthdayInChildren < ActiveRecord::Migration[7.1]
  def change
    rename_column :children, :birthdate, :birthday
  end
end