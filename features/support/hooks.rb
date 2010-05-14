Before do
	Sham.reset
	batch_file = File.expand_path(File.dirname(__FILE__) + "../../../test/ResetDB.bat")
	system("#{batch_file} > NUL")
end