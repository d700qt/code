# Packer stuff
## Packer build
### Example usage
packer build -var 'iso_url=C:\Media\Windows\Server\2016\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso' .\windows-server-2016.json

packer build -force -var-file='vars.json' .\windows-server-2016.json