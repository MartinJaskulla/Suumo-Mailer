class AddColumnsToFindDuplicates < ActiveRecord::Migration[7.0]
  def change
    add_column :apartments, :age, :integer
    add_column :apartments, :stories, :integer
    add_column :apartments, :rent, :float
    add_column :apartments, :size, :float
    add_column :apartments, :layout, :string
  end
end
