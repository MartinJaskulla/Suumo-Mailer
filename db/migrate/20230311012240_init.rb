class Init < ActiveRecord::Migration[7.0]
  def change
    create_table :queries do |t|
      t.string :url, index: {unique: true}
      t.timestamps
    end

    create_table :apartments do |t|
      t.string :href, index: {unique: true}
      t.timestamps
    end

    create_table :apartments_queries, id: false do |t|
      t.belongs_to :query
      t.belongs_to :apartment
    end
  end
end
