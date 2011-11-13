module CustomHelpers
  # Used to access the first result of a query
  def first_result
    @service_result = @service_result.first if @service_result.is_a? Enumerable
  end
  
  # Used to access the first save result
  def first_save
    @saved_result = @saved_result.first if @saved_result.is_a? Enumerable
  end
  
  # Allows the string @@LastSave to be used when checking results
  def handle_last_save_fields(val)
    if val =~ /^@@LastSave.first$/
      val = @saved_result.first
    end
    if val =~ /^@@LastSave$/
      val = @saved_result
    end
    val
  end

  # Takes in comma-delimited fields string (like key: "value") and parses it into a hash
  def parse_fields_string(fields)
    fields_hash = {}

    if !fields.nil?
      fields.split(', ').each do |field|
        if field =~ /^(?:(\w+): "(.*)")$/
          key = $1
          val = handle_last_save_fields($2)

          fields_hash.merge!({key => val})
        end
      end
    end
    fields_hash
  end
  
  # Takes in a hash and convert special values (like @@LastSave) into the appropriate values
  def parse_fields_hash(fields)
    fields_hash = {}

    if !fields.nil?
      fields.each do |key, val|        
        val = handle_last_save_fields(val)
        fields_hash.merge!({key => val})
      end
    end
    fields_hash
  end
  
end
World(CustomHelpers)