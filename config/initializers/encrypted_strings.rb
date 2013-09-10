require 'encrypted_strings'

# http://rdoc.info/github/pluginaweek/encrypted_strings/master/frames
EncryptedStrings::SymmetricCipher.default_algorithm = 'des-ecb'
EncryptedStrings::SymmetricCipher.default_password = ENV['ENCRYPTED_STRINGS_PASSWORD']

