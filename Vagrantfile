# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Define a imagem da VM a ser usada: Ubuntu 22.04 LTS (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"

  # Permitir escolher a interface física de bridge e IP via variáveis de ambiente
  # Ex.: BRIDGE_IFACE="enp3s0" VM_IP="192.168.1.150" vagrant up
  BRIDGE_IFACE = ENV.fetch('BRIDGE_IFACE', nil)
  VM_STATIC_IP = ENV['VM_IP']

  # Configurações do provedor VirtualBox
  config.vm.provider "virtualbox" do |vb|
    # Define a quantidade de memória RAM (em MB) e o número de CPUs para a VM.
    # 2GB de RAM e 2 CPUs são um bom ponto de partida para um cluster k3s.
    vb.memory = "2048"
    vb.cpus = "2"
    # Habilita modo promíscuo (útil para ARP/VIP em cenários futuros)
    vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
    # Nome legível no VirtualBox
    vb.name = 'k3s-server'
  end

  # Define um nome para a VM para fácil identificação
  config.vm.hostname = "k3s-server"

  # NIC bridged (public_network). Se VM_IP não for informado, usa DHCP da LAN
  if VM_STATIC_IP && !VM_STATIC_IP.empty?
    config.vm.network 'public_network', bridge: BRIDGE_IFACE, ip: VM_STATIC_IP
  else
    config.vm.network 'public_network', bridge: BRIDGE_IFACE
  end

  # Script de provisionamento que será executado quando a VM for criada pela primeira vez.
  # Este script instala o k3s, que é uma distribuição Kubernetes leve.
  config.vm.provision "shell", inline: <<-SHELL
    echo "=================================================="
    echo "Atualizando pacotes e instalando curl, net-tools..."
    echo "=================================================="
    apt-get update -y
    apt-get install -y curl net-tools

    echo "=================================================="
    echo "Instalando o k3s Kubernetes..."
    echo "=================================================="
    # Baixa e executa o script de instalação oficial do k3s.
    # O parâmetro '--write-kubeconfig-mode 644' torna o arquivo de configuração legível por todos os usuários.
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

    echo "=================================================="
    echo "Ambiente k3s pronto!"
    echo "Para obter o Kubeconfig, execute 'vagrant ssh' e depois:"
    echo "cat /etc/rancher/k3s/k3s.yaml"
    echo "=================================================="

    echo "IP(s) da interface bridged (IPv4):"
    ip -4 addr show | awk '/inet / {print $2, $7}'
  SHELL
end

