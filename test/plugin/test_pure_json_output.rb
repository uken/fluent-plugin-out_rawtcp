require 'test/unit'

require 'fluent/test'
require 'fluent/plugin/out_rawtcp'

require 'json'
require 'helper'

class TestRawTcpOutput < Test::Unit::TestCase
  
  def convert_hash_to_fd_configuration(conf = {})
    conf = Fluent::Config::Element.new('default_regexp_conf', '', conf, [])
  end
  
  def test_output_as_json()
    # prepare
    conf = { "output_type" => "json" }

    sut = Fluent::RawTcpOutput.new()
    sut.configure(convert_hash_to_fd_configuration(conf))
  
    tag = "testme"
    time = 123456789
    record = { "do" => "don't" }
    
    # perform - call private method here :)
    data = sut.send(:prepare_data_to_send, tag, time, record)
    
    # validate
    data_json = JSON.parse(data)
    assert(data.is_a?(String), "prepare data to send must return a String but returned #{data.class}")
    assert(data_json["do"] == "don't", "wrong json has been created")
    # endline_test = data.end_with? "\n"
    assert(!(data.end_with? '\n'), "there is new line at the end of the record to be sent")
  end

  def test_output_ends_with_newline_when_setup()
    # prepare
    conf = { "output_type" => "json", "output_append_newline" => true }

    sut = Fluent::RawTcpOutput.new()
    sut.configure(convert_hash_to_fd_configuration(conf))

    tag = "testme"
    time = 123456789
    record = { "do" => "don't" }

    # perform - call private method here :)
    data = sut.send(:prepare_data_to_send, tag, time, record)

    # validate
    assert(data.end_with? "\n", "new line has not been appended to the data to be sent")
  end

end