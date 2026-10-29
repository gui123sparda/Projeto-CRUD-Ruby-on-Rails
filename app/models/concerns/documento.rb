module Documento
  def self.valido?(value)
    return false unless value.match?(/\A(?:[0-9]{11}|[A-Z0-9]{12}[0-9]{2})\z/)
    return false if value.match?(/\A([0-9])\1+\z/)

    [ value.length - 2, value.length - 1 ].all? do |length|
      base = value[0, length]
      sum = base.chars.each_with_index.sum do |char, index|
        weight = value.length == 11 ? length + 1 - index : 2 + (length - 1 - index) % 8
        (char.ord - 48) * weight
      end
      digit = 11 - sum % 11
      value[length].to_i == (digit >= 10 ? 0 : digit)
    end
  end
end
