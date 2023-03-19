# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_19_031257) do
  create_table "apartments", force: :cascade do |t|
    t.string "href"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.integer "age"
    t.integer "stories"
    t.float "rent"
    t.float "size"
    t.string "layout"
    t.string "hash_id"
    t.index ["href"], name: "index_apartments_on_href", unique: true
  end

  create_table "apartments_queries", id: false, force: :cascade do |t|
    t.integer "query_id"
    t.integer "apartment_id"
    t.index ["apartment_id"], name: "index_apartments_queries_on_apartment_id"
    t.index ["query_id"], name: "index_apartments_queries_on_query_id"
  end

  create_table "queries", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_queries_on_url", unique: true
  end

end
