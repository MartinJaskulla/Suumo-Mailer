class AddAddressToApartment < ActiveRecord::Migration[7.0]
  def change
    add_column :apartments, :address, :string
  end
end
