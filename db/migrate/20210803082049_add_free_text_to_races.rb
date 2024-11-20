class AddFreeTextToRaces < ActiveRecord::Migration[6.1]
  def change
    add_column :races, :free_text, :text, after: :updated_at
  end
end
