require_relative '../lib/scsu'
require 'minitest/autorun'

module SCSU
  class DecoderTest < MiniTest::Test
    def setup
      @decoder = SCSU::Decoder.new
    end

    def _prepare_input input
      input.split(" ").map { |s| s.to_i(16) }.pack("c*")
    end

    def _prepare_expected expected
      expected.split(" ")
    end

    def test_decode1
      input = _prepare_input("D6 6C 20 66 6C 69 65 DF 74") # 9.1 from TR6
      expected = _prepare_expected("00D6 006C 0020 0066 006C 0069 0065 00DF 0074")
      actual = @decoder.decode(input)
      assert_equal expected, actual
    end

    def test_decode2 # 9.2 from TR6
      input = _prepare_input("12 9C BE C1 BA B2 B0")
      expected = _prepare_expected("041C 043E 0441 043A 0432 0430")
      actual = @decoder.decode(input)
      assert_equal expected, actual
    end

    def test_decode3 # 9.3 from TR6
      input = _prepare_input("
        08 00 1B 4C EA 16 CA D3 94 0F 53 EF 61 1B E5 84
        C4 0F 53 EF 61 1B E5 84 C4 16 CA D3 94 08 02 0F
        53 4A 4E 16 7D 00 30 82 52 4D 30 6B 6D 41 88 4C
        E5 97 9F 08 0C 16 CA D3 94 15 AE 0E 6B 4C 08 0D
        8C B4 A3 9F CA 99 CB 8B C2 97 CC AA 84 08 02 0E
        7C 73 E2 16 A3 B7 CB 93 D3 B4 C5 DC 9F 0E 79 3E
        06 AE B1 9D 93 D3 08 0C BE A3 8F 08 88 BE A3 8D
        D3 A8 A3 97 C5 17 89 08 0D 15 D2 08 01 93 C8 AA
        8F 0E 61 1B 99 CB 0E 4E BA 9F A1 AE 93 A8 A0 08
        02 08 0C E2 16 A3 B7 CB 0F 4F E1 80 05 EC 60 8D
        EA 06 D3 E6 0F 8A 00 30 44 65 B9 E4 FE E7 C2 06
        CB 82
      ")

      expected = _prepare_expected("
        3000 266A 30EA 30F3 30B4 53EF 611B
        3044 3084 53EF 611B 3044 3084 30EA 30F3
        30B4 3002 534A 4E16 7D00 3082 524D 306B
        6D41 884C 3057 305F 300C 30EA 30F3 30B4
        306E 6B4C 300D 304C 3074 3063 305F 308A
        3059 308B 304B 3082 3057 308C 306A 3044
        3002 7C73 30A2 30C3 30D7 30EB 30B3 30F3
        30D4 30E5 30FC 30BF 793E 306E 30D1 30BD
        30B3 30F3 300C 30DE 30C3 30AF FF08 30DE
        30C3 30AD 30F3 30C8 30C3 30B7 30E5 FF09
        300D 3092 3001 3053 3088 306A 304F 611B
        3059 308B 4EBA 305F 3061 306E 3053 3068
        3060 3002 300C 30A2 30C3 30D7 30EB 4FE1
        8005 300D 306A 3093 3066 8A00 3044 65B9
        307E 3067 3042 308B 3002
      ")

      actual = @decoder.decode(input)
      assert_equal expected, actual
    end
  end
end
