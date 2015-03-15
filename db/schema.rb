# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140805144637) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "album_photos", force: true do |t|
    t.integer  "photo_id"
    t.integer  "album_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "cover_photo", default: false, null: false
  end

  create_table "albums", force: true do |t|
    t.string   "title_es"
    t.string   "title_eu"
    t.string   "title_en"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "document_id"
    t.string   "body_es",            limit: 1000
    t.string   "body_eu",            limit: 1000
    t.string   "body_en",            limit: 1000
    t.boolean  "draft",                           default: false, null: false
    t.boolean  "featured",                        default: false
    t.integer  "album_photos_count",              default: 0
  end

  create_table "area_users", force: true do |t|
    t.integer  "area_id"
    t.integer  "user_id"
    t.integer  "position",   default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "areas", force: true do |t|
    t.string   "name_es",                       null: false
    t.string   "name_eu"
    t.string   "name_en"
    t.text     "description_es"
    t.text     "description_eu"
    t.text     "description_en"
    t.integer  "position",          default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "headline_keywords"
  end

  create_table "arguments", force: true do |t|
    t.integer  "argumentable_id",   null: false
    t.integer  "user_id",           null: false
    t.integer  "value",             null: false
    t.string   "reason",            null: false
    t.datetime "published_at"
    t.datetime "rejected_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "argumentable_type"
  end

  create_table "attachments", force: true do |t|
    t.string   "file_file_name"
    t.string   "string"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.integer  "integer"
    t.datetime "file_updated_at"
    t.datetime "datetime"
    t.integer  "attachable_id",                     null: false
    t.boolean  "show_in_es",        default: true
    t.boolean  "show_in_eu",        default: true
    t.boolean  "show_in_en",        default: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attachable_type"
  end

  add_index "attachments", ["attachable_id", "file_content_type"], name: "content_type_idx", using: :btree

  create_table "banners", force: true do |t|
    t.string   "alt_es"
    t.string   "alt_eu"
    t.string   "alt_en"
    t.string   "url_es"
    t.string   "url_eu"
    t.string   "url_en"
    t.string   "logo_es_file_name"
    t.string   "logo_es_content_type"
    t.integer  "logo_es_file_size"
    t.datetime "logo_es_updated_at"
    t.string   "logo_eu_file_name"
    t.string   "logo_eu_content_type"
    t.integer  "logo_eu_file_size"
    t.datetime "logo_eu_updated_at"
    t.string   "logo_en_file_name"
    t.string   "logo_en_content_type"
    t.integer  "logo_en_file_size"
    t.datetime "logo_en_updated_at"
    t.integer  "position",             default: 0
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bulletin_copies", force: true do |t|
    t.integer  "bulletin_id",                        null: false
    t.integer  "user_id"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.text     "news_ids",    default: "--- []\n\n", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "debate_ids",  default: "--- []\n\n", null: false
  end

  create_table "bulletins", force: true do |t|
    t.string   "title_es"
    t.string   "title_eu"
    t.string   "title_en"
    t.datetime "sent_at"
    t.text     "featured_news_ids",   default: "--- []\n\n", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "featured_debate_ids", default: "--- []\n\n", null: false
    t.datetime "send_at"
  end

  create_table "cached_keys", force: true do |t|
    t.string   "cacheable_type"
    t.integer  "cacheable_id"
    t.text     "rake_es"
    t.text     "rake_eu"
    t.text     "rake_en"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cached_keys", ["cacheable_id", "cacheable_type"], name: "index_cached_keys_on_cacheable_id_and_cacheable_type", using: :btree
  add_index "cached_keys", ["cacheable_id"], name: "index_cached_keys_on_cacheable_id", using: :btree

  create_table "categories", force: true do |t|
    t.string   "name_es",        null: false
    t.string   "name_eu",        null: false
    t.integer  "parent_id"
    t.integer  "tree_id",        null: false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "name_en"
    t.text     "description_es"
    t.text     "description_eu"
    t.text     "description_en"
  end

  create_table "clickthroughs", force: true do |t|
    t.string   "click_source_type", null: false
    t.integer  "click_source_id",   null: false
    t.string   "click_target_type"
    t.integer  "click_target_id"
    t.string   "locale",            null: false
    t.integer  "user_id"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: true do |t|
    t.integer  "commentable_id",                                      null: false
    t.string   "name",                                                null: false
    t.string   "email"
    t.text     "body"
    t.string   "status",                        default: "pendiente", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_ip"
    t.string   "user_agent",       limit: 1000
    t.text     "referrer"
    t.string   "url"
    t.integer  "abuse_counter",                 default: 0,           null: false
    t.string   "commentable_type"
    t.integer  "user_id"
    t.string   "locale",           limit: 2,    default: "es",        null: false
    t.boolean  "is_official",                   default: false,       null: false
    t.boolean  "is_answer",                     default: false,       null: false
  end

  create_table "criterios", force: true do |t|
    t.text     "title"
    t.integer  "parent_id"
    t.integer  "results_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.inet     "ip"
    t.boolean  "iphone",        default: false
    t.boolean  "only_title",    default: false
    t.string   "misspell"
  end

  create_table "debate_entities", force: true do |t|
    t.integer  "debate_id",                   null: false
    t.integer  "organization_id",             null: false
    t.integer  "position",        default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_es"
    t.string   "url_eu"
    t.string   "url_en"
  end

  create_table "debate_stages", force: true do |t|
    t.integer  "debate_id"
    t.string   "label",        limit: 20,                null: false
    t.date     "starts_on"
    t.date     "ends_on"
    t.boolean  "has_comments",            default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",                default: 0,    null: false
  end

  create_table "debates", force: true do |t|
    t.string   "title_es",          limit: 400,                 null: false
    t.string   "title_eu",          limit: 400
    t.string   "title_en",          limit: 400
    t.text     "body_es"
    t.text     "body_eu"
    t.text     "body_en"
    t.text     "description_es"
    t.text     "description_eu"
    t.text     "description_en"
    t.string   "hashtag"
    t.date     "ends_on"
    t.string   "multimedia_dir"
    t.string   "multimedia_path"
    t.string   "cover_image"
    t.string   "header_image"
    t.boolean  "featured"
    t.datetime "published_at"
    t.integer  "comments_count",                default: 0,     null: false
    t.integer  "votes_count",                   default: 0,     null: false
    t.integer  "arguments_count",               default: 0,     null: false
    t.integer  "organization_id"
    t.integer  "page_id"
    t.integer  "news_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "finished_at"
    t.boolean  "featured_bulletin",             default: false, null: false
  end

  create_table "document_tweets", force: true do |t|
    t.integer  "document_id",   null: false
    t.string   "tweet_account"
    t.datetime "tweet_at"
    t.datetime "tweeted_at"
    t.string   "tweet_locale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", force: true do |t|
    t.string   "title_es",                 limit: 400
    t.string   "title_eu",                 limit: 400
    t.text     "body_es"
    t.text     "body_eu"
    t.boolean  "has_comments",                         default: true,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.boolean  "comments_closed",                      default: false,  null: false
    t.boolean  "has_comments_with_photos",             default: false
    t.integer  "position",                             default: 100,    null: false
    t.boolean  "has_ratings",                          default: true,   null: false
    t.string   "title_en",                 limit: 400
    t.text     "body_en"
    t.datetime "published_at"
    t.string   "type",                                 default: "News", null: false
    t.integer  "comments_count",                       default: 0
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.string   "place"
    t.string   "speaker_es"
    t.decimal  "lat"
    t.decimal  "lng"
    t.string   "location_for_gmaps",       limit: 500
    t.integer  "organization_id"
    t.string   "speaker_eu"
    t.string   "speaker_en"
    t.string   "cover_photo_file_name"
    t.string   "cover_photo_content_type"
    t.integer  "cover_photo_file_size"
    t.datetime "cover_photo_updated_at"
    t.string   "cover_photo_alt_es"
    t.string   "city"
    t.boolean  "has_journalists"
    t.boolean  "has_photographers"
    t.boolean  "streaming_live",                       default: false,  null: false
    t.boolean  "irekia_coverage",                      default: false,  null: false
    t.boolean  "irekia_coverage_photo",                default: false
    t.boolean  "irekia_coverage_video",                default: false
    t.boolean  "irekia_coverage_audio",                default: false
    t.string   "cover_photo_alt_eu"
    t.string   "cover_photo_alt_en"
    t.string   "multimedia_dir"
    t.string   "multimedia_path"
    t.integer  "stream_flow_id"
    t.integer  "journalist_alert_version",             default: 0,      null: false
    t.integer  "staff_alert_version",                  default: 0,      null: false
    t.boolean  "deleted",                              default: false,  null: false
    t.datetime "ubervued_at"
    t.string   "url"
    t.datetime "exported_to_enet_at"
    t.string   "streaming_for",            limit: 50
    t.integer  "consejo_news_id"
    t.boolean  "irekia_coverage_article",              default: false
    t.string   "featured",                 limit: 5
    t.boolean  "open_in_agencia",                      default: false,  null: false
    t.text     "cached_related"
    t.boolean  "alertable",                            default: true,   null: false
    t.boolean  "featured_bulletin"
  end

  add_index "documents", ["id", "type"], name: "index_documents_on_id_and_type", using: :btree
  add_index "documents", ["published_at"], name: "index_documents_on_published_at", using: :btree
  add_index "documents", ["type", "starts_at"], name: "index_documents_on_type_and_starst_at", using: :btree

  create_table "event_alerts", force: true do |t|
    t.integer  "event_id",                              null: false
    t.integer  "spammable_id",                          null: false
    t.datetime "sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version",                   default: 0, null: false
    t.string   "spammable_type",                        null: false
    t.datetime "send_at"
    t.string   "notify_about",   limit: 30
  end

  create_table "event_locations", force: true do |t|
    t.string   "city"
    t.string   "place"
    t.string   "address"
    t.decimal  "lat"
    t.decimal  "lng"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_comments_clients", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "code"
    t.integer  "organization_id"
    t.text     "notes"
  end

  add_index "external_comments_clients", ["code"], name: "client_code_idx", unique: true, using: :btree

  create_table "external_comments_items", force: true do |t|
    t.integer  "client_id"
    t.text     "url"
    t.text     "content_path"
    t.integer  "comments_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "title"
    t.boolean  "comments_closed",  default: false, null: false
    t.integer  "irekia_news_id"
    t.string   "content_local_id"
  end

  add_index "external_comments_items", ["irekia_news_id"], name: "external_comments_item_irekia_news_id_idx", using: :btree

  create_table "followings", force: true do |t|
    t.integer  "user_id"
    t.integer  "followed_id"
    t.string   "followed_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "headlines", force: true do |t|
    t.text     "title"
    t.text     "body"
    t.string   "source_item_type"
    t.string   "source_item_id"
    t.string   "locale"
    t.string   "url"
    t.string   "media_name"
    t.datetime "published_at"
    t.boolean  "draft"
    t.float    "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tweets"
  end

  create_table "notifications", force: true do |t|
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.string   "action"
    t.integer  "counter"
    t.datetime "read_at"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "old_clickthroughs", force: true do |t|
    t.string   "source_type",    null: false
    t.integer  "source_id",      null: false
    t.string   "target_type",    null: false
    t.integer  "target_id",      null: false
    t.string   "locale",         null: false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.string   "source_subtype"
    t.string   "target_subtype"
  end

  create_table "orders", force: true do |t|
    t.date     "fecha_bol"
    t.date     "fecha_disp"
    t.string   "dept_es",     limit: 500
    t.string   "dept_eu",     limit: 500
    t.string   "materias_es", limit: 500
    t.string   "materias_eu", limit: 500
    t.string   "no_bol"
    t.string   "no_disp"
    t.string   "no_orden"
    t.string   "rango_es"
    t.string   "rango_eu"
    t.string   "seccion_es"
    t.string   "seccion_eu"
    t.text     "titulo_es"
    t.text     "titulo_eu"
    t.text     "texto_es"
    t.text     "texto_eu"
    t.text     "ref_ant_es"
    t.text     "ref_pos_es"
    t.text     "vigencia_es"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "vigencia_eu"
    t.text     "ref_ant_eu"
    t.text     "ref_pos_eu"
  end

  add_index "orders", ["no_orden"], name: "index_orders_on_no_orden", using: :btree

  create_table "organizations", force: true do |t|
    t.string   "name_es",                              null: false
    t.string   "name_eu"
    t.string   "name_en"
    t.string   "type"
    t.string   "kind"
    t.integer  "position",              default: 0
    t.integer  "parent_id"
    t.string   "tag_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gc_id"
    t.boolean  "active",                default: true, null: false
    t.string   "term",       limit: 10
  end

  create_table "outside_organizations", force: true do |t|
    t.string   "name_es",    null: false
    t.string   "name_eu"
    t.string   "name_en"
    t.string   "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: true do |t|
    t.integer  "user_id"
    t.string   "module"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", force: true do |t|
    t.string   "title_es"
    t.string   "title_eu"
    t.string   "title_en"
    t.string   "file_path",             null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "date_time_original"
    t.datetime "date_time_digitalized"
    t.integer  "width"
    t.integer  "exif_image_length"
    t.string   "city"
    t.string   "province_state"
    t.string   "country"
    t.integer  "height"
    t.integer  "document_id"
  end

  create_table "proposals", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "title_es"
    t.string   "title_eu"
    t.string   "title_en"
    t.text     "body_es"
    t.text     "body_eu"
    t.text     "body_en"
    t.string   "url"
    t.string   "status",          default: "pendiente", null: false
    t.string   "user_ip"
    t.boolean  "has_comments",    default: true,        null: false
    t.boolean  "comments_closed", default: false,       null: false
    t.integer  "comments_count",  default: 0,           null: false
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "user_id"
    t.integer  "organization_id"
    t.boolean  "featured",        default: false,       null: false
    t.integer  "votes_count",     default: 0,           null: false
    t.integer  "arguments_count", default: 0,           null: false
    t.string   "image"
  end

  add_index "proposals", ["status"], name: "contribution_status_idx", using: :btree

  create_table "ratings", force: true do |t|
    t.integer "rating"
    t.integer "rateable_id",   null: false
    t.string  "rateable_type", null: false
  end

  add_index "ratings", ["rateable_id", "rating"], name: "index_ratings_on_rateable_id_and_rating", using: :btree

  create_table "recommendation_ratings", force: true do |t|
    t.string   "source_type", null: false
    t.integer  "source_id",   null: false
    t.string   "target_type", null: false
    t.integer  "target_id",   null: false
    t.decimal  "rating",      null: false
    t.integer  "user_id",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "related_events", force: true do |t|
    t.string   "eventable_type"
    t.integer  "eventable_id"
    t.integer  "event_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "room_managements", force: true do |t|
    t.integer  "streaming_id"
    t.integer  "room_manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schedules_permissions", force: true do |t|
    t.integer  "schedule_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "can_edit",            default: true,  null: false
    t.boolean  "can_change_schedule", default: false, null: false
  end

  create_table "session_logs", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "action",     null: false
    t.datetime "action_at",  null: false
    t.string   "user_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "snetworks", force: true do |t|
    t.integer "sorganization_id"
    t.string  "url"
    t.string  "label"
    t.integer "position"
  end

  create_table "sorganizations", force: true do |t|
    t.integer  "department_id"
    t.string   "name_es"
    t.string   "name_eu"
    t.string   "name_en"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
  end

  create_table "stats_counters", force: true do |t|
    t.integer  "countable_id"
    t.string   "countable_type"
    t.string   "countable_subtype"
    t.datetime "published_at"
    t.integer  "department_id"
    t.integer  "organization_id"
    t.integer  "area_id"
    t.integer  "comments"
    t.integer  "official_comments"
    t.integer  "answer_time_in_seconds"
    t.integer  "arguments"
    t.integer  "in_favor_arguments"
    t.integer  "against_arguments"
    t.integer  "votes"
    t.integer  "positive_votes"
    t.integer  "negative_votes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_comments"
    t.integer  "twitter_comments"
    t.integer  "not_twitter_comments"
  end

  add_index "stats_counters", ["area_id"], name: "index_stats_counters_on_area_id", using: :btree
  add_index "stats_counters", ["countable_type"], name: "index_stats_counters_on_countable_type", using: :btree
  add_index "stats_counters", ["department_id"], name: "index_stats_counters_on_department_id", using: :btree

  create_table "stats_fs", id: false, force: true do |t|
    t.integer  "mpg",        null: false
    t.integer  "mp3",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stream_flows", force: true do |t|
    t.string   "title_es",                            null: false
    t.string   "title_eu"
    t.string   "title_en"
    t.string   "code",                                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "show_in_irekia",      default: false
    t.boolean  "announced_in_irekia", default: false
    t.integer  "event_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.boolean  "send_alerts",         default: true
    t.integer  "position",            default: 0
    t.boolean  "mobile_support",      default: false, null: false
  end

  create_table "subscriptions", force: true do |t|
    t.integer  "user_id",       null: false
    t.integer  "department_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "survey_responses", force: true do |t|
    t.integer  "survey_id",             null: false
    t.integer  "created_by"
    t.string   "ip_address", limit: 20
    t.string   "locale",     limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surveys", force: true do |t|
    t.string   "title_es"
    t.string   "title_eu"
    t.string   "title_en"
    t.text     "description_es"
    t.text     "description_eu"
    t.text     "description_en"
    t.integer  "state"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_ejes", force: true do |t|
    t.string   "sanitized_name"
    t.integer  "eje_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree
  add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name_es",                           null: false
    t.string  "name_eu",                           null: false
    t.string  "sanitized_name_es",                 null: false
    t.string  "sanitized_name_eu",                 null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string  "name_en",                           null: false
    t.string  "sanitized_name_en",                 null: false
    t.boolean "translated",        default: false
    t.string  "kind"
    t.string  "kind_info"
    t.integer "criterio_id"
  end

  create_table "trees", force: true do |t|
    t.string   "name_es",    null: false
    t.string   "name_eu",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_en"
    t.string   "label"
  end

  create_table "twitter_mentions", force: true do |t|
    t.string   "tweet_id",           null: false
    t.string   "user_name",          null: false
    t.text     "tweet_text",         null: false
    t.text     "tweet_entities"
    t.text     "tweet_decoded_urls"
    t.datetime "tweet_published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "twitter_mentions", ["tweet_id"], name: "index_twitter_mentions_on_tweet_id", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "crypted_password",          limit: 40
    t.string   "salt",                      limit: 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "status",                    limit: 10, default: "aprobado"
    t.string   "name"
    t.string   "last_names"
    t.string   "raw_location"
    t.decimal  "lat"
    t.decimal  "lng"
    t.string   "city"
    t.string   "state"
    t.string   "country_code"
    t.string   "zip"
    t.string   "user_ip"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "url"
    t.string   "type"
    t.string   "media"
    t.string   "organization"
    t.integer  "department_id"
    t.string   "telephone"
    t.string   "alerts_locale",             limit: 2,  default: "es",       null: false
    t.string   "screen_name"
    t.string   "atoken"
    t.string   "asecret"
    t.string   "fb_id"
    t.string   "public_role_es"
    t.string   "public_role_eu"
    t.string   "public_role_en"
    t.text     "description_es"
    t.text     "description_eu"
    t.text     "description_en"
    t.integer  "gc_id"
    t.string   "department_role",           limit: 30
    t.string   "photo"
    t.boolean  "politician_has_agenda"
    t.string   "googleplus_id"
    t.boolean  "wants_bulletin",                       default: false,      null: false
    t.datetime "bulletin_sent_at"
    t.string   "bulletin_email"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
  end

  create_table "videos", force: true do |t|
    t.string   "title_es",                  limit: 400
    t.string   "title_eu",                  limit: 400
    t.string   "title_en",                  limit: 400
    t.string   "video_path"
    t.datetime "published_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.boolean  "has_comments",                          default: true,  null: false
    t.boolean  "comments_closed",                       default: false, null: false
    t.integer  "comments_count",                        default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "featured",                              default: false, null: false
    t.boolean  "show_in_es",                            default: true,  null: false
    t.boolean  "show_in_eu",                            default: true,  null: false
    t.boolean  "show_in_en",                            default: true,  null: false
    t.datetime "ubervued_at"
    t.integer  "document_id"
    t.integer  "duration"
    t.string   "display_format",            limit: 5
    t.string   "subtitles_es_file_name"
    t.string   "subtitles_es_content_type"
    t.integer  "subtitles_es_file_size"
    t.datetime "subtitles_es_updated_at"
    t.integer  "subtitles_es_updated_by"
    t.string   "subtitles_eu_file_name"
    t.string   "subtitles_eu_content_type"
    t.integer  "subtitles_eu_file_size"
    t.datetime "subtitles_eu_updated_at"
    t.integer  "subtitles_eu_updated_by"
    t.string   "subtitles_en_file_name"
    t.string   "subtitles_en_content_type"
    t.integer  "subtitles_en_file_size"
    t.datetime "subtitles_en_updated_at"
    t.integer  "subtitles_en_updated_by"
  end

  create_table "votes", force: true do |t|
    t.integer  "votable_id",   null: false
    t.integer  "user_id",      null: false
    t.integer  "value",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "votable_type"
  end

end
