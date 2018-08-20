
module SimpleEncryption
  ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  #generated with .split('').shuffle.join
  ENCODING = "MOhqm0PnycUZeLdK8YvDCgNfb7FJtiHT52BrxoAkas9RWlXpEujSGI64VzQ31w"

  def self.encrypt(text)
    return text.tr(ALPHABET, ENCODING)
  end

  def self.decrypt(text)
    return text.tr(ENCODING, ALPHABET)
  end


end
