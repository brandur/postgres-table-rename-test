require 'sequel'

BATCH_SIZE = 100

def main
  material = ENV["MATERIAL"]
  table_name = ENV["TABLE_NAME"]&.to_sym || abort("want TABLE_NAME")

  db = Sequel.connect("postgres://localhost:5432/postgres-table-rename-test")

  loop do
    BATCH_SIZE.times do
      fields = { diameter: 20, num_teeth: 26 }
      fields[:material] = material if material

      db[table_name].insert(fields)
      db[table_name].order(:id).last
    end
    puts "Inserted and read #{BATCH_SIZE} records of '#{table_name}'"
    sleep(0.1)
  end
end

main