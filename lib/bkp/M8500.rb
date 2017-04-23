require 'serialport'

module BKP

	class M8500

		def initialize(config=nil)
			@config = config unless config == nil
			@sp = SerialPort.new(@config[:port_str], @config[:baud_rate], @config[:data_bits], @config[:stop_bits], @config[:parity])
			@sp.flow_control = SerialPort::NONE
			@sp.binmode
			@sp.read_timeout = 2000
			#puts @sp.methods
			#puts @sp.get_signals
		end

		def close()
			#puts @sp.get_signals
			@sp.close()
		end

		def cmd(command)
			@sp.write command.pack('C*')
			resp = @sp.read(26).bytes
			return resp
		end

		def Remote(state)
			packet = BuildPacket("\x20", (state ? "\x01" : "\x00"))
			reply = cmd(packet)
			if CalculateChecksum(reply) == reply[25]
				if reply[2] == 18
					data = {	:header => reply[0],
									:address => reply[1],
									:status => reply[3],
									:checksum => reply[25]
									}

					data[:status] = case data[:status]
					when 144
						"Checksum incorrect"
					when 160
						"Parameter incorrect"
					when 176
						"Unrecognized command"
					when 192
						"Invalid command"
					when 128
						"Command was successful"
					else
						"Wut?"
					end
					return data
				end
			end
		end

		def LoadEnable(state)
			packet = BuildPacket("\x21", (state ? "\x01" : "\x00"))
			reply = cmd(packet)
			if CalculateChecksum(reply) == reply[25]
				return DecodeStatus(reply) if reply[2] == 18
			end
		end

		def DecodeStatus(packet)
			if CalculateChecksum(packet) == packet[25]
				if packet[2] == 18
					data = {	:header => packet[0],
									:address => packet[1],
									:status => packet[3],
									:checksum => packet[25]
									}

					data[:status] = case data[:status]
					when 144
						"Checksum incorrect"
					when 160
						"Parameter incorrect"
					when 176
						"Unrecognized command"
					when 192
						"Invalid command"
					when 128
						"Command was successful"
					else
						"Wut?"
					end
					return data
				end
			end
		end

		def ReadDisplay()
			reply = cmd(BuildPacket("\x5F"))
			data = {
				:voltage => (reply[3..6].reverse.pack('C*').unpack("N")[0].to_i * 0.001),
				:current => (reply[7..10].reverse.pack('C*').unpack("N")[0].to_i * 0.0001),
				:power => (reply[11..14].reverse.pack('C*').unpack("N")[0].to_i * 0.001),
				:operation_state =>  sprintf('%08b', reply[15]).split("").map { |n| n.eql?('1') ? true : false },
				:demand_state => sprintf('%010b', reply[16..17].reverse.pack('C*').unpack("N")[0].to_i).split("").map { |n| n.eql?('1') ? true : false }
			}

			data[:operation_state] = {	:demarcation_coefficient => data[:operation_state][0],
																:trigger_wait => data[:operation_state][1],
																:remote_control => data[:operation_state][2],
																:output => data[:operation_state][3],
																:local_key => data[:operation_state][4],
																:remote_sense => data[:operation_state][5],
																:load => data[:operation_state][6],
																:load_timer => data[:operation_state][7],
																}

			data[:demand_state] = {	:reverse_voltage => data[:demand_state][0],
															:over_voltage => data[:demand_state][1],
															:over_current => data[:demand_state][2],
															:over_power => data[:demand_state][3],
															:over_temp => data[:demand_state][4],
															:not_connected => data[:demand_state][5],
															:constant_current => data[:demand_state][6],
															:constant_voltage => data[:demand_state][7],
															:constant_power => data[:demand_state][8],
															:constant_resistance => data[:demand_state][9],
														}
			data[:voltage] = ('%.3f' % data[:voltage]).to_f
			data[:current] = ('%.3f' % data[:current]).to_f
			data[:power] = ('%.3f' % data[:power]).to_f
			return data if CalculateChecksum(reply) == reply[25]
		end

		def GetBatMin()
			reply = cmd(BuildPacket("\x4F"))
			volts = reply[3..6].reverse.pack('C*').unpack("N")[0].to_i * 0.0001
			return volts
		end

		def SetBatMin(volts)
			reply = cmd(BuildPacket("\x4E", [(volts * 1000)].pack('V')))
			if CalculateChecksum(reply) == reply[25]
				return DecodeStatus(reply) if reply[2] == 18
			end
		end

		def GetCurrent()
			reply = cmd(BuildPacket("\x2B"))
			current = reply[3..6].reverse.pack('C*').unpack("N")[0].to_i * 0.0001
			return current
		end

		def SetCurrent(current)
			reply = cmd(BuildPacket("\x2A", [(current * 10000)].pack('V')))
			if CalculateChecksum(reply) == reply[25]
				return DecodeStatus(reply) if reply[2] == 18
			end
		end

		def GetSense()
			reply = cmd(BuildPacket("\x57"))
			return reply[3]
		end

		def GetMode()
			reply = cmd(BuildPacket("\x5E"))
			return reply[3]
		end

		def SetMode(mode)
			reply = cmd(BuildPacket("\x5D", mode))
			if CalculateChecksum(reply) == reply[25]
				return DecodeStatus(reply) if reply[2] == 18
			end
		end

		def CalculateChecksum(packet)
			packet_length = 26
			packet = packet.bytes if packet.is_a?(String)
			return unless (packet.length == packet_length - 1) or (packet.length == packet_length)
			checksum = packet[0..24].reduce(:+) % 256
			return checksum
		end

		def BuildPacket(command, args = nil)

			args = Array.new(22).fill("\x00").join if args == nil

			packet = Array.new(26)

			packet.fill(0)

			packet[0..1] = "\xAA\x00".unpack('C*')

			packet[2] = command.unpack('C*')[0]

			packet[3..(args.unpack('C*').length + 3)] = args.unpack('C*')

			packet[25] = CalculateChecksum(packet)

			return packet
		end

	end
end
