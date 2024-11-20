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

ActiveRecord::Schema.define(version: 2022_09_26_034307) do

  create_table "active_storage_attachments", charset: "utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "annual_schedules", charset: "utf8mb4", force: :cascade do |t|
    t.string "pf_id", null: false
    t.date "first_day"
    t.string "track_code"
    t.integer "hold_days"
    t.boolean "pre_day"
    t.string "year_name"
    t.string "year_name_en"
    t.integer "period"
    t.integer "round"
    t.boolean "girl"
    t.integer "promoter_times"
    t.integer "promoter_section"
    t.integer "time_zone"
    t.boolean "audience"
    t.string "grade_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "promoter_year"
    t.boolean "active", default: false, null: false
    t.index ["pf_id"], name: "index_annual_schedules_on_pf_id", unique: true
  end

  create_table "bike_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_player_id", null: false
    t.string "frame_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_player_id"], name: "index_bike_infos_on_race_player_id"
  end

  create_table "campaign_hold_daily_schedules", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "hold_daily_schedule_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["campaign_id"], name: "index_campaign_hold_daily_schedules_on_campaign_id"
    t.index ["hold_daily_schedule_id"], name: "index_campaign_hold_daily_schedules_on_hold_daily_schedule_id"
  end

  create_table "campaign_master_seat_types", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "master_seat_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["campaign_id"], name: "index_campaign_master_seat_types_on_campaign_id"
    t.index ["master_seat_type_id"], name: "index_campaign_master_seat_types_on_master_seat_type_id"
  end

  create_table "campaign_usages", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "order_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["campaign_id"], name: "index_campaign_usages_on_campaign_id"
    t.index ["order_id"], name: "index_campaign_usages_on_order_id"
  end

  create_table "campaigns", charset: "utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.string "code", null: false, collation: "utf8mb4_bin"
    t.integer "discount_rate", null: false
    t.integer "usage_limit", default: 9999999, null: false
    t.string "description"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "approved_at"
    t.datetime "terminated_at"
    t.boolean "displayable", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_campaigns_on_code", unique: true
  end

  create_table "coupon_hold_daily_conditions", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "coupon_id", null: false
    t.bigint "hold_daily_schedule_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["coupon_id", "hold_daily_schedule_id"], name: "coupon_and_hold_daily_index", unique: true
    t.index ["coupon_id"], name: "index_coupon_hold_daily_conditions_on_coupon_id"
    t.index ["hold_daily_schedule_id"], name: "index_coupon_hold_daily_conditions_on_hold_daily_schedule_id"
  end

  create_table "coupon_seat_type_conditions", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "coupon_id", null: false
    t.bigint "master_seat_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["coupon_id", "master_seat_type_id"], name: "coupon_and_seat_type_index", unique: true
    t.index ["coupon_id"], name: "index_coupon_seat_type_conditions_on_coupon_id"
    t.index ["master_seat_type_id"], name: "index_coupon_seat_type_conditions_on_master_seat_type_id"
  end

  create_table "coupons", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "template_coupon_id", null: false
    t.datetime "available_end_at", null: false
    t.datetime "scheduled_distributed_at"
    t.datetime "approved_at"
    t.datetime "canceled_at"
    t.boolean "user_restricted", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["template_coupon_id"], name: "index_coupons_on_template_coupon_id"
  end

  create_table "entrances", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "track_id", null: false
    t.string "entrance_code", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["track_id"], name: "index_entrances_on_track_id"
  end

  create_table "external_api_logs", charset: "utf8mb4", force: :cascade do |t|
    t.string "host"
    t.string "path"
    t.text "request_params"
    t.integer "response_http_status"
    t.text "response_params", size: :long
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "front_wheel_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "bike_info_id", null: false
    t.string "wheel_code"
    t.integer "rental_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["bike_info_id"], name: "index_front_wheel_infos_on_bike_info_id"
  end

  create_table "hold_dailies", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_id", null: false
    t.integer "hold_id_daily", null: false
    t.date "event_date", null: false
    t.integer "hold_daily", null: false
    t.integer "daily_branch", null: false
    t.integer "program_count"
    t.integer "race_count", null: false
    t.integer "daily_status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hold_id"], name: "index_hold_dailies_on_hold_id"
  end

  create_table "hold_daily_schedules", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_daily_id", null: false
    t.integer "daily_no", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hold_daily_id"], name: "index_hold_daily_schedules_on_hold_daily_id"
  end

  create_table "hold_player_results", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_player_id", null: false
    t.bigint "race_result_player_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hold_player_id"], name: "index_hold_player_results_on_hold_player_id"
    t.index ["race_result_player_id"], name: "index_hold_player_results_on_race_result_player_id", unique: true
  end

  create_table "hold_players", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_id"
    t.bigint "last_hold_player_id"
    t.bigint "last_ranked_hold_player_id"
    t.bigint "player_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hold_id"], name: "index_hold_players_on_hold_id"
    t.index ["last_hold_player_id"], name: "index_hold_players_on_last_hold_player_id"
    t.index ["last_ranked_hold_player_id"], name: "index_hold_players_on_last_ranked_hold_player_id"
    t.index ["player_id"], name: "index_hold_players_on_player_id"
  end

  create_table "hold_titles", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "player_result_id", null: false
    t.string "pf_hold_id"
    t.integer "period"
    t.integer "round"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["player_result_id"], name: "index_hold_titles_on_player_result_id"
  end

  create_table "holds", charset: "utf8mb4", force: :cascade do |t|
    t.string "pf_hold_id", null: false
    t.string "track_code", null: false
    t.date "first_day", null: false
    t.integer "hold_days", null: false
    t.string "grade_code", null: false
    t.string "purpose_code", null: false
    t.string "repletion_code"
    t.string "hold_name_jp"
    t.string "hold_name_en"
    t.integer "hold_status"
    t.string "promoter_code", null: false
    t.integer "promoter_year"
    t.integer "promoter_times"
    t.integer "promoter_section"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "tt_movie_yt_id"
    t.string "season"
    t.integer "period"
    t.integer "round"
    t.boolean "girl"
    t.string "promoter"
    t.integer "time_zone"
    t.boolean "audience"
    t.string "title_jp"
    t.string "title_en"
    t.date "first_day_manually"
    t.index ["hold_status"], name: "index_holds_on_hold_status"
    t.index ["pf_hold_id"], name: "index_holds_on_pf_hold_id", unique: true
  end

  create_table "master_seat_areas", charset: "utf8mb4", force: :cascade do |t|
    t.string "area_name", null: false
    t.string "position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "area_code", null: false
    t.string "sub_position"
    t.string "sub_code"
  end

  create_table "master_seat_types", charset: "utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "master_seat_units", charset: "utf8mb4", force: :cascade do |t|
    t.integer "seat_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "unit_name"
  end

  create_table "master_seats", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "master_seat_type_id", null: false
    t.bigint "master_seat_area_id", null: false
    t.bigint "master_seat_unit_id"
    t.string "row"
    t.integer "seat_number", null: false
    t.integer "sales_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["master_seat_area_id"], name: "index_master_seats_on_master_seat_area_id"
    t.index ["master_seat_type_id"], name: "index_master_seats_on_master_seat_type_id"
    t.index ["master_seat_unit_id"], name: "index_master_seats_on_master_seat_unit_id"
  end

  create_table "mediated_players", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_player_id"
    t.string "pf_player_id"
    t.integer "regist_num"
    t.string "issue_code"
    t.string "grade_code"
    t.string "repletion_code"
    t.string "race_code"
    t.string "first_race_code"
    t.string "entry_code"
    t.string "pattern_code"
    t.string "miss_day"
    t.string "join_code"
    t.string "change_code"
    t.string "add_day"
    t.string "add_issue_id"
    t.string "add_issue_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hold_player_id"], name: "index_mediated_players_on_hold_player_id"
  end

  create_table "odds_details", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "odds_list_id", null: false
    t.string "tip1", null: false
    t.string "tip2"
    t.string "tip3"
    t.decimal "odds_val", precision: 6, scale: 1, null: false
    t.decimal "odds_max_val", precision: 6, scale: 1
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["odds_list_id"], name: "index_odds_details_on_odds_list_id"
  end

  create_table "odds_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.string "entries_id", null: false
    t.datetime "odds_time", null: false
    t.boolean "fixed", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_odds_infos_on_race_detail_id"
  end

  create_table "odds_lists", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "odds_info_id", null: false
    t.integer "vote_type", null: false
    t.integer "odds_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["odds_info_id"], name: "index_odds_lists_on_odds_info_id"
  end

  create_table "orders", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "order_at", null: false
    t.integer "order_type", null: false
    t.integer "total_price", null: false
    t.bigint "seat_sale_id"
    t.bigint "user_coupon_id"
    t.integer "option_discount", default: 0, null: false
    t.integer "coupon_discount", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "returned_at"
    t.string "refund_error_message"
    t.integer "campaign_discount", default: 0, null: false
    t.index ["seat_sale_id"], name: "index_orders_on_seat_sale_id"
    t.index ["user_coupon_id"], name: "index_orders_on_user_coupon_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "charge_id", null: false
    t.integer "payment_progress", default: 0, null: false
    t.datetime "captured_at"
    t.datetime "refunded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "payoff_lists", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.integer "payoff_type"
    t.integer "vote_type"
    t.string "tip1", null: false
    t.string "tip2"
    t.string "tip3"
    t.integer "payoff"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_payoff_lists_on_race_detail_id"
  end

  create_table "player_original_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.string "last_name_jp"
    t.string "first_name_jp"
    t.string "last_name_en"
    t.string "first_name_en"
    t.integer "speed"
    t.integer "stamina"
    t.integer "power"
    t.integer "technique"
    t.integer "mental"
    t.integer "growth"
    t.integer "original_record"
    t.integer "popular"
    t.integer "experience"
    t.integer "evaluation"
    t.string "nickname"
    t.string "comment"
    t.string "season_best"
    t.string "year_best"
    t.string "round_best"
    t.string "race_type"
    t.string "major_title"
    t.string "pist6_title"
    t.text "free1"
    t.text "free2"
    t.text "free3"
    t.text "free4"
    t.text "free5"
    t.text "free6"
    t.text "free7"
    t.text "free8"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "pf_250_regist_id"
    t.index ["pf_250_regist_id"], name: "index_player_original_infos_on_pf_250_regist_id"
    t.index ["player_id"], name: "index_player_original_infos_on_player_id"
  end

  create_table "player_race_results", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.date "event_date"
    t.integer "hold_daily"
    t.integer "daily_status"
    t.integer "race_no"
    t.integer "race_status"
    t.integer "rank"
    t.string "time"
    t.string "event_code"
    t.string "hold_id"
    t.string "entries_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["player_id"], name: "index_player_race_results_on_player_id"
  end

  create_table "player_results", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "player_id"
    t.string "pf_player_id"
    t.integer "entry_count"
    t.integer "run_count"
    t.integer "consecutive_count"
    t.integer "first_count"
    t.integer "second_count"
    t.integer "third_count"
    t.integer "outside_count"
    t.integer "first_place_count"
    t.integer "second_place_count"
    t.integer "third_place_count"
    t.float "winner_rate"
    t.float "second_quinella_rate"
    t.float "third_quinella_rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["player_id"], name: "index_player_results_on_player_id"
  end

  create_table "players", charset: "utf8mb4", force: :cascade do |t|
    t.string "pf_player_id"
    t.integer "regist_num"
    t.integer "player_class"
    t.date "regist_day"
    t.date "delete_day"
    t.date "keirin_regist"
    t.date "keirin_update"
    t.date "keirin_delete"
    t.date "keirin_expiration"
    t.date "middle_regist"
    t.date "middle_update"
    t.date "middle_delete"
    t.date "middle_expiration"
    t.string "name_jp"
    t.string "name_en"
    t.date "birthday"
    t.integer "gender_code"
    t.string "country_code"
    t.string "area_code"
    t.integer "graduate"
    t.string "current_rank_code"
    t.string "next_rank_code"
    t.decimal "height", precision: 4, scale: 1
    t.decimal "weight", precision: 4, scale: 1
    t.decimal "chest", precision: 4, scale: 1
    t.decimal "thigh", precision: 4, scale: 1
    t.decimal "leftgrip", precision: 3, scale: 1
    t.decimal "rightgrip", precision: 3, scale: 1
    t.decimal "vital", precision: 5, scale: 1
    t.decimal "spine", precision: 5, scale: 1
    t.string "lap_200"
    t.string "lap_400"
    t.string "lap_1000"
    t.decimal "max_speed", precision: 4, scale: 2
    t.decimal "dash", precision: 4, scale: 2
    t.decimal "duration", precision: 4, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "catchphrase"
    t.index ["pf_player_id"], name: "index_players_on_pf_player_id"
  end

  create_table "profiles", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "family_name", null: false
    t.string "given_name", null: false
    t.string "family_name_kana", null: false
    t.string "given_name_kana", null: false
    t.date "birthday", null: false
    t.string "zip_code"
    t.string "prefecture"
    t.string "city"
    t.string "address_line"
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "mailmagazine", default: false, null: false
    t.string "phone_number"
    t.text "auth_code"
    t.boolean "ng_user_check", default: true, null: false
    t.string "address_detail"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "race_details", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_id", null: false
    t.string "pf_hold_id", null: false
    t.integer "hold_id_daily", null: false
    t.string "track_code"
    t.string "hold_day"
    t.date "first_day"
    t.integer "hold_daily"
    t.integer "daily_branch"
    t.string "entries_id", null: false
    t.string "bike_count"
    t.integer "race_distance"
    t.integer "laps_count"
    t.string "pattern_code"
    t.string "post_time"
    t.string "grade_code"
    t.string "repletion_code"
    t.integer "time_zone_code"
    t.string "race_code"
    t.string "first_race_code"
    t.string "entry_code"
    t.string "type_code"
    t.string "event_code"
    t.string "details_code"
    t.string "race_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "close_time"
    t.index ["race_id"], name: "index_race_details_on_race_id"
  end

  create_table "race_player_stats", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_player_id", null: false
    t.float "winner_rate"
    t.float "second_quinella_rate"
    t.float "third_quinella_rate"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_player_id"], name: "index_race_player_stats_on_race_player_id"
  end

  create_table "race_players", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.integer "bracket_no"
    t.integer "bike_no"
    t.string "pf_player_id"
    t.decimal "gear", precision: 3, scale: 2
    t.boolean "miss", null: false
    t.integer "start_position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_race_players_on_race_detail_id"
  end

  create_table "race_result_players", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_result_id", null: false
    t.integer "bike_no"
    t.string "pf_player_id"
    t.integer "incoming"
    t.integer "rank"
    t.integer "point"
    t.string "trick_code"
    t.string "difference_code"
    t.boolean "home_class"
    t.boolean "back_class"
    t.integer "start_position"
    t.decimal "last_lap", precision: 6, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["pf_player_id"], name: "index_race_result_players_on_pf_player_id"
    t.index ["race_result_id"], name: "index_race_result_players_on_race_result_id"
    t.index ["rank"], name: "index_race_result_players_on_rank"
  end

  create_table "race_results", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.string "entries_id", null: false
    t.integer "bike_count"
    t.string "race_stts"
    t.string "post_time"
    t.decimal "race_time", precision: 6, scale: 4
    t.decimal "last_lap", precision: 6, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_race_results_on_race_detail_id"
  end

  create_table "races", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_daily_schedule_id", null: false
    t.integer "program_no", null: false
    t.integer "race_no", null: false
    t.integer "time_zone_code"
    t.string "post_time"
    t.integer "race_distance", null: false
    t.integer "lap_count", null: false
    t.string "pattern_code"
    t.string "race_code", null: false
    t.string "first_race_code"
    t.string "entry_code"
    t.string "type_code"
    t.string "event_code"
    t.string "details_code"
    t.datetime "post_start_time", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "free_text"
    t.string "race_movie_yt_id"
    t.string "interview_movie_yt_id"
    t.string "entries_id"
    t.index ["hold_daily_schedule_id"], name: "index_races_on_hold_daily_schedule_id"
  end

  create_table "ranks", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.integer "car_number", null: false
    t.integer "arrival_order", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_ranks_on_race_detail_id"
  end

  create_table "rear_wheel_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "bike_info_id", null: false
    t.string "wheel_code"
    t.integer "rental_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["bike_info_id"], name: "index_rear_wheel_infos_on_bike_info_id"
  end

  create_table "result_event_codes", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_result_player_id", null: false
    t.integer "priority", null: false
    t.string "event_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_result_player_id"], name: "index_result_event_codes_on_race_result_player_id"
  end

  create_table "retired_players", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.datetime "retired_at", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["player_id"], name: "index_retired_players_on_player_id", unique: true
  end

  create_table "seat_areas", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "seat_sale_id", null: false
    t.bigint "master_seat_area_id", null: false
    t.boolean "displayable", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "entrance_id"
    t.index ["entrance_id"], name: "index_seat_areas_on_entrance_id"
    t.index ["master_seat_area_id"], name: "index_seat_areas_on_master_seat_area_id"
    t.index ["seat_sale_id"], name: "index_seat_areas_on_seat_sale_id"
  end

  create_table "seat_sales", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "template_seat_sale_id"
    t.bigint "hold_daily_schedule_id"
    t.integer "sales_status", default: 0, null: false
    t.datetime "sales_start_at", null: false
    t.datetime "sales_end_at", null: false
    t.datetime "admission_available_at", null: false
    t.datetime "admission_close_at", null: false
    t.datetime "force_sales_stop_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "refund_at"
    t.datetime "refund_end_at"
    t.index ["hold_daily_schedule_id"], name: "index_seat_sales_on_hold_daily_schedule_id"
    t.index ["template_seat_sale_id"], name: "index_seat_sales_on_template_seat_sale_id"
  end

  create_table "seat_type_options", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "seat_type_id", null: false
    t.bigint "template_seat_type_option_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["seat_type_id"], name: "index_seat_type_options_on_seat_type_id"
    t.index ["template_seat_type_option_id"], name: "index_seat_type_options_on_template_seat_type_option_id"
  end

  create_table "seat_types", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "seat_sale_id", null: false
    t.bigint "master_seat_type_id", null: false
    t.bigint "template_seat_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["master_seat_type_id"], name: "index_seat_types_on_master_seat_type_id"
    t.index ["seat_sale_id"], name: "index_seat_types_on_seat_sale_id"
    t.index ["template_seat_type_id"], name: "index_seat_types_on_template_seat_type_id"
  end

  create_table "template_coupons", charset: "utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.integer "rate", null: false
    t.text "note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "template_seat_areas", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "master_seat_area_id", null: false
    t.bigint "template_seat_sale_id", null: false
    t.boolean "displayable", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "entrance_id"
    t.index ["entrance_id"], name: "index_template_seat_areas_on_entrance_id"
    t.index ["master_seat_area_id"], name: "index_template_seat_areas_on_master_seat_area_id"
    t.index ["template_seat_sale_id"], name: "index_template_seat_areas_on_template_seat_sale_id"
  end

  create_table "template_seat_sale_schedules", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "template_seat_sale_id", null: false
    t.string "sales_end_time", null: false
    t.string "admission_available_time", null: false
    t.string "admission_close_time", null: false
    t.integer "target_hold_schedule", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["template_seat_sale_id"], name: "index_template_seat_sale_schedules_on_template_seat_sale_id"
  end

  create_table "template_seat_sales", charset: "utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.string "description"
    t.integer "status", default: 0, null: false
    t.boolean "immutable", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "template_seat_type_options", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "template_seat_type_id", null: false
    t.string "title", null: false
    t.integer "price", null: false
    t.boolean "companion", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "description"
    t.index ["template_seat_type_id"], name: "index_template_seat_type_options_on_template_seat_type_id"
  end

  create_table "template_seat_types", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "master_seat_type_id", null: false
    t.bigint "template_seat_sale_id", null: false
    t.integer "price", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["master_seat_type_id"], name: "index_template_seat_types_on_master_seat_type_id"
    t.index ["template_seat_sale_id"], name: "index_template_seat_types_on_template_seat_sale_id"
  end

  create_table "template_seats", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "master_seat_id", null: false
    t.bigint "template_seat_area_id", null: false
    t.bigint "template_seat_type_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["master_seat_id"], name: "index_template_seats_on_master_seat_id"
    t.index ["template_seat_area_id"], name: "index_template_seats_on_template_seat_area_id"
    t.index ["template_seat_type_id"], name: "index_template_seats_on_template_seat_type_id"
  end

  create_table "ticket_logs", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "ticket_id"
    t.integer "log_type", null: false
    t.integer "request_status", null: false
    t.integer "status", null: false
    t.integer "result", null: false
    t.integer "face_recognition"
    t.integer "result_status", null: false
    t.integer "failed_message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "device_id"
    t.index ["ticket_id"], name: "index_ticket_logs_on_ticket_id"
  end

  create_table "ticket_reserves", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "ticket_id"
    t.bigint "seat_type_option_id"
    t.datetime "transfer_at"
    t.integer "transfer_to_user_id"
    t.integer "transfer_from_user_id"
    t.bigint "next_ticket_reserve_id"
    t.bigint "previous_ticket_reserve_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["next_ticket_reserve_id"], name: "fk_rails_8e89099d87"
    t.index ["order_id"], name: "index_ticket_reserves_on_order_id"
    t.index ["previous_ticket_reserve_id"], name: "fk_rails_42a1e40625"
    t.index ["seat_type_option_id"], name: "index_ticket_reserves_on_seat_type_option_id"
    t.index ["ticket_id"], name: "index_ticket_reserves_on_ticket_id"
  end

  create_table "tickets", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "seat_area_id", null: false
    t.bigint "seat_type_id", null: false
    t.bigint "user_id"
    t.bigint "purchase_ticket_reserve_id"
    t.bigint "current_ticket_reserve_id"
    t.bigint "master_seat_unit_id"
    t.string "row"
    t.integer "seat_number", null: false
    t.integer "status", default: 0, null: false
    t.integer "sales_type", default: 0, null: false
    t.string "transfer_uuid"
    t.string "qr_ticket_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "admission_disabled_at"
    t.index ["current_ticket_reserve_id"], name: "fk_rails_aa4180ad50"
    t.index ["master_seat_unit_id"], name: "index_tickets_on_master_seat_unit_id"
    t.index ["purchase_ticket_reserve_id"], name: "fk_rails_a75cd836ef"
    t.index ["seat_area_id"], name: "index_tickets_on_seat_area_id"
    t.index ["seat_type_id"], name: "index_tickets_on_seat_type_id"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "time_trial_bike_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "time_trial_player_id", null: false
    t.string "frame_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["time_trial_player_id"], name: "index_time_trial_bike_infos_on_time_trial_player_id"
  end

  create_table "time_trial_front_wheel_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "time_trial_bike_info_id", null: false
    t.string "wheel_code"
    t.integer "rental_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["time_trial_bike_info_id"], name: "index_time_trial_front_wheel_infos_on_time_trial_bike_info_id"
  end

  create_table "time_trial_players", charset: "utf8mb4", force: :cascade do |t|
    t.string "first_race_code"
    t.string "entry_code"
    t.bigint "time_trial_result_id", null: false
    t.string "pf_player_id"
    t.decimal "gear", precision: 3, scale: 2
    t.string "grade_code"
    t.decimal "first_time", precision: 6, scale: 4
    t.decimal "second_time", precision: 6, scale: 4
    t.decimal "total_time", precision: 6, scale: 4
    t.integer "ranking"
    t.string "repletion_code"
    t.string "race_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "pattern_code"
    t.index ["time_trial_result_id"], name: "index_time_trial_players_on_time_trial_result_id"
  end

  create_table "time_trial_rear_wheel_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "time_trial_bike_info_id", null: false
    t.string "wheel_code"
    t.integer "rental_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["time_trial_bike_info_id"], name: "index_time_trial_rear_wheel_infos_on_time_trial_bike_info_id"
  end

  create_table "time_trial_results", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "hold_id", null: false
    t.string "pf_hold_id", null: false
    t.boolean "confirm"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "players"
    t.index ["hold_id"], name: "index_time_trial_results_on_hold_id"
  end

  create_table "tracks", charset: "utf8mb4", force: :cascade do |t|
    t.string "track_code", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "user_coupons", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "coupon_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["coupon_id", "user_id"], name: "index_user_coupons_on_coupon_id_and_user_id", unique: true
    t.index ["coupon_id"], name: "index_user_coupons_on_coupon_id"
    t.index ["user_id"], name: "index_user_coupons_on_user_id"
  end

  create_table "users", charset: "utf8mb4", force: :cascade do |t|
    t.string "sixgram_id", null: false
    t.string "qr_user_id"
    t.boolean "email_verified", default: false, null: false
    t.string "email_auth_code"
    t.datetime "email_auth_expired_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "unsubscribe_uuid"
    t.datetime "unsubscribe_mail_sent_at"
    t.index ["sixgram_id"], name: "index_users_on_sixgram_id", unique: true
  end

  create_table "visitor_profiles", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.string "sixgram_id", null: false
    t.string "family_name", null: false
    t.string "given_name", null: false
    t.string "family_name_kana", null: false
    t.string "given_name_kana", null: false
    t.date "birthday", null: false
    t.string "zip_code"
    t.string "prefecture"
    t.string "city"
    t.string "address_line"
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "address_detail"
    t.index ["ticket_id"], name: "index_visitor_profiles_on_ticket_id"
  end

  create_table "vote_infos", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "race_detail_id", null: false
    t.integer "vote_type"
    t.integer "vote_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["race_detail_id"], name: "index_vote_infos_on_race_detail_id"
  end

  create_table "word_codes", charset: "utf8mb4", force: :cascade do |t|
    t.string "master_id", null: false
    t.string "identifier", null: false
    t.string "code"
    t.string "name1"
    t.string "name2"
    t.string "name3"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["master_id"], name: "index_word_codes_on_master_id", unique: true
  end

  create_table "word_names", charset: "utf8mb4", force: :cascade do |t|
    t.integer "word_code_id", null: false
    t.string "lang", null: false
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bike_infos", "race_players"
  add_foreign_key "campaign_hold_daily_schedules", "campaigns"
  add_foreign_key "campaign_hold_daily_schedules", "hold_daily_schedules"
  add_foreign_key "campaign_master_seat_types", "campaigns"
  add_foreign_key "campaign_master_seat_types", "master_seat_types"
  add_foreign_key "campaign_usages", "campaigns"
  add_foreign_key "campaign_usages", "orders"
  add_foreign_key "coupon_hold_daily_conditions", "coupons"
  add_foreign_key "coupon_hold_daily_conditions", "hold_daily_schedules"
  add_foreign_key "coupon_seat_type_conditions", "coupons"
  add_foreign_key "coupon_seat_type_conditions", "master_seat_types"
  add_foreign_key "coupons", "template_coupons"
  add_foreign_key "entrances", "tracks"
  add_foreign_key "front_wheel_infos", "bike_infos"
  add_foreign_key "hold_dailies", "holds"
  add_foreign_key "hold_daily_schedules", "hold_dailies"
  add_foreign_key "hold_player_results", "hold_players"
  add_foreign_key "hold_player_results", "race_result_players"
  add_foreign_key "hold_players", "hold_players", column: "last_hold_player_id"
  add_foreign_key "hold_players", "hold_players", column: "last_ranked_hold_player_id"
  add_foreign_key "hold_players", "holds"
  add_foreign_key "hold_players", "players"
  add_foreign_key "hold_titles", "player_results"
  add_foreign_key "master_seats", "master_seat_areas"
  add_foreign_key "master_seats", "master_seat_types"
  add_foreign_key "master_seats", "master_seat_units"
  add_foreign_key "mediated_players", "hold_players"
  add_foreign_key "odds_details", "odds_lists"
  add_foreign_key "odds_infos", "race_details"
  add_foreign_key "odds_lists", "odds_infos"
  add_foreign_key "orders", "seat_sales"
  add_foreign_key "orders", "user_coupons"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "payoff_lists", "race_details"
  add_foreign_key "player_original_infos", "players"
  add_foreign_key "player_race_results", "players"
  add_foreign_key "player_results", "players"
  add_foreign_key "profiles", "users"
  add_foreign_key "race_details", "races"
  add_foreign_key "race_player_stats", "race_players"
  add_foreign_key "race_players", "race_details"
  add_foreign_key "race_result_players", "race_results"
  add_foreign_key "race_results", "race_details"
  add_foreign_key "races", "hold_daily_schedules"
  add_foreign_key "ranks", "race_details"
  add_foreign_key "rear_wheel_infos", "bike_infos"
  add_foreign_key "result_event_codes", "race_result_players"
  add_foreign_key "retired_players", "players"
  add_foreign_key "seat_areas", "entrances"
  add_foreign_key "seat_areas", "master_seat_areas"
  add_foreign_key "seat_areas", "seat_sales"
  add_foreign_key "seat_sales", "hold_daily_schedules"
  add_foreign_key "seat_sales", "template_seat_sales"
  add_foreign_key "seat_type_options", "seat_types"
  add_foreign_key "seat_type_options", "template_seat_type_options"
  add_foreign_key "seat_types", "master_seat_types"
  add_foreign_key "seat_types", "seat_sales"
  add_foreign_key "seat_types", "template_seat_types"
  add_foreign_key "template_seat_areas", "entrances"
  add_foreign_key "template_seat_areas", "master_seat_areas"
  add_foreign_key "template_seat_areas", "template_seat_sales"
  add_foreign_key "template_seat_sale_schedules", "template_seat_sales"
  add_foreign_key "template_seat_type_options", "template_seat_types"
  add_foreign_key "template_seat_types", "master_seat_types"
  add_foreign_key "template_seat_types", "template_seat_sales"
  add_foreign_key "template_seats", "master_seats"
  add_foreign_key "template_seats", "template_seat_areas"
  add_foreign_key "template_seats", "template_seat_types"
  add_foreign_key "ticket_logs", "tickets"
  add_foreign_key "ticket_reserves", "orders"
  add_foreign_key "ticket_reserves", "seat_type_options"
  add_foreign_key "ticket_reserves", "ticket_reserves", column: "next_ticket_reserve_id"
  add_foreign_key "ticket_reserves", "ticket_reserves", column: "previous_ticket_reserve_id"
  add_foreign_key "ticket_reserves", "tickets"
  add_foreign_key "tickets", "master_seat_units"
  add_foreign_key "tickets", "seat_areas"
  add_foreign_key "tickets", "seat_types"
  add_foreign_key "tickets", "ticket_reserves", column: "current_ticket_reserve_id"
  add_foreign_key "tickets", "ticket_reserves", column: "purchase_ticket_reserve_id"
  add_foreign_key "tickets", "users"
  add_foreign_key "time_trial_bike_infos", "time_trial_players"
  add_foreign_key "time_trial_front_wheel_infos", "time_trial_bike_infos"
  add_foreign_key "time_trial_players", "time_trial_results"
  add_foreign_key "time_trial_rear_wheel_infos", "time_trial_bike_infos"
  add_foreign_key "time_trial_results", "holds"
  add_foreign_key "user_coupons", "coupons"
  add_foreign_key "user_coupons", "users"
  add_foreign_key "visitor_profiles", "tickets"
  add_foreign_key "vote_infos", "race_details"
end
