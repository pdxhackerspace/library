module IsbnCode
  module_function

  def normalize(raw)
    raw.to_s.gsub(/[^0-9X]/i, '').upcase
  end

  def valid?(raw)
    code = normalize(raw)
    isbn10?(code) || isbn13?(code)
  end

  def isbn10?(code)
    normalize(code).match?(/\A\d{9}[\dX]\z/)
  end

  def isbn13?(code)
    normalized = normalize(code)
    normalized.match?(/\A97[89]\d{10}\z/) && check_digit_valid?(normalized)
  end

  def check_digit_valid?(code)
    digits = code.chars.map(&:to_i)
    sum = digits.each_with_index.sum do |digit, index|
      if index < 12
        digit * (index.even? ? 1 : 3)
      else
        0
      end
    end
    check = (10 - (sum % 10)) % 10
    check == digits.last
  end
end
