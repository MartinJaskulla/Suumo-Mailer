class AddHashToApartment < ActiveRecord::Migration[7.0]
  def change
    add_column :apartments, :hash_id, :string
  end
end
