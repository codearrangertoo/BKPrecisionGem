require 'serialport'

module BKP

  class M1900B

    def initialize(config)
      @sp = SerialPort.new(config[:port_str], config[:baud_rate], config[:data_bits], config[:stop_bits], config[:parity])
      @sp.flow_control = SerialPort::NONE
			@sp.read_timeout = 2000
    end
    
    def cmd(command)
    	@sp.write command + "\r"
    	data = @sp.readline("\r").chomp
    	return data if data == "OK"
    	resp = @sp.readline("\r").chomp
    	return data if resp == "OK"
    end
    
    #Get voltage and current setting values from power supply
    def gets()
    	resp = cmd("GETS").chars.to_a
    	v = resp[0..2].join.to_f * 0.1
    	a = resp[3..5].join.to_f * 0.1
    	a = '%.1f' % a
    	v = '%.1f' % v
    	return [v.to_f, a.to_f]
    end
    
    #Get display voltage, current, and status reading from power supply
    def getd()
    	resp = cmd("GETD").chars.to_a
    	v = resp[0..3].join.to_f * 0.01
    	a = resp[4..7].join.to_f * 0.01
    	a = '%.2f' % a
    	v = '%.2f' % v
    	status = ((resp[8].to_i == 0) ? "CV" : "CC")
    	return [v.to_f, a.to_f, status]
    end
    
    #Set voltage level
    def volt(v)
    	max = 32
    	v = max if v > max
    	v = (v * 10)
    	v = '%03u' % v
    	cmd("VOLT#{v}")
    end
    
    #Set upper voltage limit of power supply
    def sovp(v)
    	max = 32
    	v = max if v > max
    	v = (v * 10)
    	v = "%03u" % v
    	cmd("SOVP#{v}")
    end
    
    #Set upper current limit of power supply
    def socp(a)
    	max = 30
    	a = max if a > max
    	a = (a * 10)
    	a = "%03u" % a
    	puts "a:", a
    	cmd("SOCP#{a}")
    end
    
    #Set current level
    def curr(a)
    	max = 30
    	a = max if a > max
    	a = (a * 10)
    	a = "%03u" % a
    	cmd("CURR#{a}")
    end
    
    #Output On/Off control true = on false = off
    def sout(state)
    	state = (state ? 0 : 1)
    	cmd("SOUT#{state}")
    end
    
    #Get upper voltage limit of power supply
    def govp()
    	cmd("GOVP").to_i * 0.1
    end
    
    #Get upper current limit of power supply
    def gocp()
    	cmd("GOCP").to_i * 0.1
    end
    
    #Get power supply maximum voltage and current values
    def gmax()
    	resp = cmd("GMAX").chars.to_a
    	volts = resp[0..2].join.to_f * 0.1
    	current = resp[3..5].join.to_f * 0.1
    	return [volts, current]
    end
    
    #Set voltage and current using values saved in preset memory locations
    def runm(mode)
    	cmd("RUNM#{mode.to_i}")
    end
    
  end
end
