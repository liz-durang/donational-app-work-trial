require 'csv'

module Organizations
  class CreateOrUpdateTaxExemptOrganizationsFromCSV < ApplicationCommand

    def execute
      delete_sql = "DELETE FROM searchable_organizations;"
      ActiveRecord::Base.connection.execute(delete_sql)

      import_searchable_organizations_from_csv("db/tax_exempt_organizations/eo1.csv")
      import_searchable_organizations_from_csv("db/tax_exempt_organizations/eo2.csv")
      import_searchable_organizations_from_csv("db/tax_exempt_organizations/eo3.csv")

      nil
    end

    private

    def import_searchable_organizations_from_csv(path)
      File.open(path, 'r') do |io|
        connection = ActiveRecord::Base.connection
        connection.raw_connection.copy_data %{COPY searchable_organizations FROM STDIN CSV HEADER} do
          while line = io.gets do
            next if line.strip.size == 0
            connection.raw_connection.put_copy_data line
          end
        end
      end
    end
  end
end
