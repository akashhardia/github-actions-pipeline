class CreateVoteInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :vote_infos do |t|
      t.references :race_detail, null: false, foreign_key: true
      t.integer :vote_type
      t.integer :vote_status

      t.timestamps
      end
  end
end
