# CSV
Mime::Type.register "text/csv", :csv unless Mime::Type.lookup_by_extension(:csv)
# XLSX
Mime::Type.register "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx unless Mime::Type.lookup_by_extension(:xlsx)
