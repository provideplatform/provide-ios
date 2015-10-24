
desc 'generate certificate signing request'
task :csr do
  `openssl req -out request.csr -new -newkey rsa:2048 -nodes -keyout key.pem`
end

desc 'convert certification from DER to PEM'
task :der_to_pem do
  `openssl x509 -inform der -in apple-delivered.cer -out apple-delivered.pem`
end

desc 'create pkcs12 bundle using certificate delivered by apple'
task :pkcs12 do
  `openssl x509 -inform der -in apple-delivered.cer -outform pem -out cert.pem`
  `openssl pkcs12 -export -inkey key.pem -in cert.pem -out key-cert-bundle.p12`
end
