# Como criar a box local do Mikrotik CHR

1) Baixe o CHR OVA oficial (ex.: `chr-7.15.3.ova`) do site da Mikrotik.
2) Importe no VirtualBox, ligue uma vez para gerar o disco VDI.
3) Converta/empacote como box local:
```
mkdir -p build/chr
cd build/chr
# Copie o VMDK/VDI exportado (ex.: chr.vdi) para este diretório

cat > metadata.json <<'EOF'
{
  "provider": "virtualbox",
  "format": "virtualbox-ovf",
  "virtual_size": 2
}
EOF

cat > Vagrantfile <<'EOF'
Vagrant.configure('2') do |config|
  config.vm.provider 'virtualbox' do |vb|
    vb.customize ['storagectl', :id, '--name', 'SATA Controller', '--add', 'sata']
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 0, '--device', 0, '--type', 'hdd', '--medium', 'chr.vdi']
  end
end
EOF

vagrant package --base <NOME_VM_CHR_NO_VIRTUALBOX> --output mikrotik-chr.box
vagrant box add --name local/mikrotik-chr mikrotik-chr.box --force
```
4) Volte ao diretório `routeros` e rode `BRIDGE_IFACE=<iface> vagrant up`.
