class CreateCoupons < ActiveRecord::Migration[6.0]
  def change
    create_table :coupons do |t|
      t.references :template_coupon, null: false, foreign_key: true
      t.datetime :available_end_at, null: false
      t.datetime :scheduled_distributed_at
      t.datetime :approved_at
      t.datetime :canceled_at
      t.boolean :user_restricted, null: false, default: false

      t.timestamps
    end
  end
end
