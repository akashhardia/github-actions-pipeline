class AddColumnDescriptionToTemplateSeatTypeOption < ActiveRecord::Migration[6.0]
  def change
    add_column :template_seat_type_options, :description, :string
  end
end
