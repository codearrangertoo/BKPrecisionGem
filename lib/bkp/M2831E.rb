require 'serialport'

module BKP

  class M2831E

    def initialize(config)        
      @sp = SerialPort.new(config[:port_str], config[:baud_rate], config[:data_bits], config[:stop_bits], config[:parity])
      # @sp.flow_control = SerialPort::NONE

    end

    def cmd(command)
      @sp.write command + "\n"
    	resp = @sp.gets.chomp
    	if resp == command
    		resp = @sp.gets.chomp
    	end
    	return resp
    end
    
    def fetch()
    	cmd(":FETCh?").to_f
    end
    
    def idn()
      cmd("*IDN?")
    end

  end
end
