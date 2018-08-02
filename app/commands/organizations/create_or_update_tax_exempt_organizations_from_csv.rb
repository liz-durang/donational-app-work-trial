require 'csv'

module Organizations
  class CreateOrUpdateTaxExemptOrganizationsFromCSV < ApplicationCommand

    def execute
      delete_sql = "DELETE FROM searchable_organizations;"
      ActiveRecord::Base.connection.execute(delete_sql)

      copy_from("db/tax_exempt_organizations/eo1.csv")
      copy_from("db/tax_exempt_organizations/eo2.csv")
      copy_from("db/tax_exempt_organizations/eo3.csv")

      nil
    end

    private

    def copy_from(path)
      io = File.open(path, 'r')
      connection = ActiveRecord::Base.connection
      connection.raw_connection.copy_data %{COPY searchable_organizations FROM STDIN CSV HEADER} do
        while line = io.gets do
          next if line.strip.size == 0
          if block_given?
            row = CSV.parse_line(line.strip, { col_sep: ',' })
            yield(row)
            next if row.all? { |f| f.nil? }
            line = CSV.generate_line(row, { col_sep: ',' })
          end
          connection.raw_connection.put_copy_data line
        end
      end
    end
  end
end
