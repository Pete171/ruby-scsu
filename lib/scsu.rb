module SCSU
  SINGLE_BYTE_MODE = 'single_byte_mode'
  UNICODE_MODE = 'unicode_mode'

  STATIC_WINDOWS = {
    0 => 0x0000,
    1 => 0x0080,
    2 => 0x0100,
    3 => 0x0300,
    4 => 0x2000,
    5 => 0x2080,
    6 => 0x2100,
    7 => 0x3000,
  }

  def self.get_initial_dynamic_windows
    {
      0 => 0x0080,
      1 => 0x00C0,
      2 => 0x0400,
      3 => 0x0600,
      4 => 0x0900,
      5 => 0x3040,
      6 => 0x30A0,
      7 => 0xFF00,
    }
  end

  class Decoder
    def decode(input)
      @mode = SCSU::SINGLE_BYTE_MODE
      @dynamic_windows = SCSU::get_initial_dynamic_windows
      @active_window = 0
      @output = []
      @string_io = StringIO.new(input)

      while byte = @string_io.read(1)
        byte = byte.ord
        if @mode == SCSU::SINGLE_BYTE_MODE then
          _handle_single_byte_mode(byte)
        else
          _handle_unicode_mode(byte)
        end
      end
      @output
    end

    private

    def _read_byte
      @string_io.read(1).ord
    end

    def _write_code_point(code_point)
      @output << code_point.to_s(16).upcase.rjust(4, "0")
    end

    def _calculate_window_position(x)
      map = [
        [0xF9, 0x00C0],
        [0xFA, 0x0250],
        [0xFB, 0x0370],
        [0xFC, 0x0530],
        [0xFD, 0x3040],
        [0xFE, 0x30A0],
        [0xFF, 0xFF60],
      ]

      if (0x01..0x67).include?(x) then
        x * 0x80
      elsif (0x68..0xA7).include?(x) then
        x * 0x80 + 0xAC00
      elsif (val = map.assoc(x)) then
        val[1]
      else
        raise "Reserved."
      end
    end

    def _handle_unicode_mode(byte)
      case byte
      when 0xE0..0xE7 # UC0-UC7
        _handle_ucn(byte)
      when 0xE8..0xEF #UD0-UD7
        _handle_udn(byte)
      when 0xF0 #UQU
        _handle_uqu()
      when 0xF1 #UDX
        raise NotImplementedError, "TODO"  #TODO
      else # literal char
        _handle_literal_utf16(byte)
      end
    end

    def _handle_ucn(byte)
      @mode = SCSU::SINGLE_BYTE_MODE
      window = byte - 0xE0
      @active_window = window
    end

    def _handle_udn(byte)
      window = byte - 0xE8
      input = _read_byte
      offset = _calculate_window_position(input)
      @dynamic_windows[window] = offset
      @active_window = window
      @mode = SCSU::SINGLE_BYTE_MODE
    end

    def _handle_uqu
      hbyte = _read_byte
      lbyte = _read_byte
      _write_code_point(hbyte)
      _write_code_point(lbyte)
    end

    def _handle_literal_utf16(byte)
      code_point = (byte << 8) + _read_byte
      _write_code_point(code_point)
    end

    def _handle_single_byte_mode(byte)
      case byte
      when 0x01..0x08 # SQ0-7
        _handle_sqn(byte)
      when 0x0B # SDX
        raise NotImplementedError, "TODO" #TODO.
      when 0x0E #SQU
        _handle_squ
      when 0x0F # SCU
        _handle_scu
      when 0x10..0x17 #SC0-SC7
        _handle_scn(byte)
      when 0x18..0x1F #SD0-SD7
        _handle_sdn(byte)
      when 0x20..0x7F #static window
        _handle_static_window(byte, 0)
      when [0x09, 0x0A, 0x0D].include?(byte)
        _handle_static_window(byte, 0)
      when 0x80..0xFF #dynamic window
        _handle_dynamic_window(byte)
      end
    end

    def _handle_sqn(byte)
      byte = byte - 0x01
      original_window = @active_window
      @active_window = byte

      next_byte = _read_byte

      if (0x00..0x7F).include?(next_byte) then
        _handle_static_window(next_byte, @active_window)
      else
        _handle_dynamic_window(next_byte)
      end

      @active_window = original_window
    end

    def _handle_squ
      code_point = (_read_byte << 8) + _read_byte
      _write_code_point(code_point)
    end

    def _handle_scu
      @mode = SCSU::UNICODE_MODE
    end

    def _handle_scn(byte)
      @active_window = byte - 0x10
    end

    def _handle_sdn(byte)
      window = byte - 0x18
      input = _read_byte
      offset = _calculate_window_position(input)
      @dynamic_windows[window] = offset
      @active_window = window
    end

    def _handle_static_window(byte, window = 0)
      window_offset = STATIC_WINDOWS[window]
      byte = window_offset + byte
      _write_code_point(byte)
    end

    def _handle_dynamic_window(byte)
      offset =  @dynamic_windows[@active_window]
      output = offset + byte - 0x80
      _write_code_point(output)
    end
  end
end
