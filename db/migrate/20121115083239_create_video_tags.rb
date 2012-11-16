class CreateVideoTags < ActiveRecord::Migration
  def change
    create_table :video_tags do |t|
      t.references :site

      t.string  :uid
      t.string  :uid_origin
      t.string  :name
      t.string  :name_origin
      t.string  :video_id
      t.string  :video_id_origin

      t.text    :poster_url
      t.string  :size
      t.integer :duration # ms

      t.text    :sources # Serialized Hash
      t.text    :current_sources # Serialized Array
      t.hstore  :settings

      t.timestamps
    end

    add_index :video_tags, [:site_id, :uid], unique: true
    add_index :video_tags, [:site_id, :updated_at]
  end
end
