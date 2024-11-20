csv_dir = 'db/fixtures/csv/'

track_data = CSV.read(Rails.root.join(csv_dir + 'tracks.csv'), headers: true)
entrance_data = CSV.read(Rails.root.join(csv_dir + 'entrances.csv'), headers: true)

master_seat_type_data = CSV.read(Rails.root.join(csv_dir + 'master_seat_types.csv'), headers: true)
master_seat_area_data = CSV.read(Rails.root.join(csv_dir + 'master_seat_areas.csv'), headers: true)
master_seat_unit_data = CSV.read(Rails.root.join(csv_dir + 'master_seat_units.csv'), headers: true)

master_seat_data_paths = Rails.root.join("#{csv_dir}/master_seats").glob("*.csv").sort
master_seat_data_arr = master_seat_data_paths.map { |path| CSV.read(path, headers: true) }

template_seat_sale_data = CSV.read(Rails.root.join(csv_dir + 'template_seat_sales.csv'), headers: true)
template_seat_type_data = CSV.read(Rails.root.join(csv_dir + 'template_seat_types.csv'), headers: true)
template_seat_type_option_data = CSV.read(Rails.root.join(csv_dir + 'template_seat_type_options.csv'), headers: true)
template_seat_area_data = CSV.read(Rails.root.join(csv_dir + 'template_seat_areas.csv'), headers: true)

# 競技場
tracks = track_data.map do |data|
  Track.new(
    id: data['track_index'],
    track_code: data['track_code'],
    name: data['name']
  )
end
Track.import! tracks, on_duplicate_key_update: [:track_code, :name]

# 入場口
entrances = entrance_data.map do |data|
  Entrance.new(
    id: data['entrance_index'],
    track_id: data['track_index'],
    entrance_code: data['entrance_code'],
    name: data['name']
  )
end
Entrance.import! entrances, on_duplicate_key_update: [:track_id, :entrance_code, :name]

# 席種マスター
master_seat_types = master_seat_type_data.map do |data|
  MasterSeatType.new(id: data['master_seat_type_index'], name: data['name'])
end
MasterSeatType.import! master_seat_types, on_duplicate_key_update: [:name]

# エリアマスター
master_seat_areas = master_seat_area_data.map do |data|
  MasterSeatArea.new(id: data['master_seat_area_index'], area_code: data['area_code'], area_name: data['area_name'], position: data['position'], sub_position: data['sub_position'], sub_code: data['sub_code'])
end
MasterSeatArea.import! master_seat_areas, on_duplicate_key_update: [:area_code, :area_name, :position, :sub_position, :sub_code]

# Unit席マスター
master_seat_units = master_seat_unit_data.map do |data|
  MasterSeatUnit.new(id: data['master_seat_unit_index'], seat_type: data['seat_type'], unit_name: data['unit_name'])
end
MasterSeatUnit.import! master_seat_units, on_duplicate_key_update: [:seat_type, :unit_name]

# 座席マスター
master_seat_index = 1
master_seats = master_seat_data_arr.flat_map do |master_seat_data|
  master_seat_data.map do |data|
    master_seat = MasterSeat.new(
      id: master_seat_index,
      master_seat_type_id: data['master_seat_type_index'],
      master_seat_area_id: data['master_seat_area_index'],
      master_seat_unit_id: data['master_seat_unit_index'],
      row: data['row'],
      seat_number: data['seat_number'],
      sales_type: data['sales_type']
    )
    master_seat_index += 1
    master_seat
  end
end

MasterSeat.import! master_seats, on_duplicate_key_update: [:master_seat_type_id, :master_seat_area_id, :master_seat_unit_id, :row, :seat_number, :sales_type]

# 販売テンプレート
template_seat_sales = template_seat_sale_data.map do |data|
  TemplateSeatSale.new(
    id: data['template_seat_sale_index'],
    title: data['title'],
    description: data['description'],
    immutable: data['immutable']
  )
end
TemplateSeatSale.import! template_seat_sales, on_duplicate_key_update: [:title, :description, :immutable]

# 席種テンプレート
template_seat_types = template_seat_type_data.map do |data|
  TemplateSeatType.new(
    id: data['template_seat_type_index'],
    master_seat_type_id: data['master_seat_type_index'],
    template_seat_sale_id: data['template_seat_sale_index'],
    price: data['price']
  )
end
TemplateSeatType.import! template_seat_types, on_duplicate_key_update: [:master_seat_type_id, :template_seat_sale_id, :price]

# 席種オプションテンプレート
template_seat_type_options = template_seat_type_option_data.map do |data|
  TemplateSeatTypeOption.new(
    id: data['template_seat_type_option_index'],
    template_seat_type_id: data['template_seat_type_index'],
    title: data['title'],
    price: data['price'],
    companion: data['companion'],
    description: data['description']
  )
end
TemplateSeatTypeOption.import! template_seat_type_options, on_duplicate_key_update: [:template_seat_type_id, :title, :price, :companion, :description]

# エリアテンプレート
template_seat_areas = template_seat_area_data.map do |data|
  TemplateSeatArea.new(
    id: data['template_seat_area_index'],
    template_seat_sale_id: data['template_seat_sale_index'],
    master_seat_area_id: data['master_seat_area_index'],
    displayable: data['displayable'],
    entrance_id: data['entrance_id']
  )
end
TemplateSeatArea.import! template_seat_areas, on_duplicate_key_update: [:template_seat_sale_id, :master_seat_area_id, :displayable, :entrance_id]

# 座席テンプレート

template_seat_index = 1

template_seats = []
template_seat_sale_data.each do |template_seat_sale|
  template_seat_sale_id = template_seat_sale['template_seat_sale_index']
  MasterSeat.all.each do |master_seat|
    template_seat_type = template_seat_type_data.find do |d|
      d['template_seat_sale_index'] == template_seat_sale_id && d['master_seat_type_index'].to_i == master_seat.master_seat_type_id
    end

    template_seat_area = template_seat_area_data.find do |d|
      d['template_seat_sale_index'] == template_seat_sale_id && d['master_seat_area_index'].to_i == master_seat.master_seat_area_id
    end

    template_seats << TemplateSeat.new(
      id: template_seat_index,
      master_seat_id: master_seat.id,
      template_seat_type_id: template_seat_type['template_seat_type_index'],
      template_seat_area_id: template_seat_area['template_seat_area_index'],
      status: template_seat_area['displayable'] == '1' ? :available : :not_for_sale
    )

    template_seat_index += 1
  end
end

TemplateSeat.import! template_seats, on_duplicate_key_update: [:master_seat_id, :template_seat_type_id, :template_seat_area_id, :status]

# 自動生成バリュー
template_seat_sale_schedules = 4.times.map do |n|
  is_day_time = n.even?
  TemplateSeatSaleSchedule.new(
    id: n + 1,
    template_seat_sale_id: TemplateSeatSale.first.id,
    sales_end_time: is_day_time ? '14:30' : '20:00',
    admission_available_time:  is_day_time ? '10:30' : '16:00',
    admission_close_time:  is_day_time ? '15:00' : '20:30',
    target_hold_schedule: n
  )
end

TemplateSeatSaleSchedule.import! template_seat_sale_schedules, on_duplicate_key_update: [:template_seat_sale_id, :sales_end_time, :admission_available_time, :admission_close_time, :target_hold_schedule]
