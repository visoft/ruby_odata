Before do
	Sham.reset
	batch_file = File.expand_path(File.dirname(__FILE__) + "../../../test/ResetDB.bat")
	output = `"#{batch_file}`
end