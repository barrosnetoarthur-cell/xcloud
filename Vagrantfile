# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Define a imagem da VM a ser usada: Ubuntu 22.04 LTS (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"
  
  # Configurações globais para acelerar
  config.vm.provider "virtualbox" do |vb|
    # Otimizações gerais de performance
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
  end

  # Definir ordem de inicialização: servers primeiro, depois agents
  servers = [
    {name: 'prod-cp1', cpus: 2, mem: 4096, ip: '192.168.56.101', k3s_role: 'server', k3s_vip: '192.168.56.200'},
    {name: 'stg-cp1',  cpus: 2, mem: 4096, ip: '192.168.56.121', k3s_role: 'server', k3s_vip: '192.168.56.210'},
  ]
  
  agents = [
    {name: 'prod-w1',  cpus: 4, mem: 8192, ip: '192.168.56.111', k3s_role: 'agent', k3s_server_ip: '192.168.56.101', disks: [200]},
    {name: 'stg-w1',   cpus: 4, mem: 6144, ip: '192.168.56.122', k3s_role: 'agent', k3s_server_ip: '192.168.56.121', disks: [150]},
  ]

  K3S_TOKEN = "K108bc71968fade9a31d0e8e046e8afd531542ac8c3be599c7bc1df13be506cbe67::server:07a87c5385e1e02f11e3e2e7e2b826dc"
  K3S_VERSION = "v1.33.4+k3s1"  # Fixar versão para cache

  # Script comum para acelerar apt e baixar k3s
  common_setup = <<-SCRIPT
    set -eux
    export DEBIAN_FRONTEND=noninteractive
    
    # Acelerar apt
    echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90assumeyes
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90norecommends
    
    # Update rápido
    apt-get update -qq
    apt-get install -y curl jq wget
    
    # Pré-download k3s binary para cache
    if [ ! -f /usr/local/bin/k3s ]; then
      echo "Baixando k3s #{K3S_VERSION}..."
      wget -q https://github.com/k3s-io/k3s/releases/download/#{K3S_VERSION}/k3s -O /usr/local/bin/k3s
      chmod +x /usr/local/bin/k3s
    fi
  SCRIPT

  # Processar servers primeiro
  (servers + agents).each do |n|
    config.vm.define n[:name] do |node|
      node.vm.hostname = n[:name]
      node.vm.network 'private_network', ip: n[:ip]

      node.vm.provider 'virtualbox' do |vb|
        vb.name   = n[:name]
        vb.cpus   = n[:cpus]
        vb.memory = n[:mem]
        vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
        # Otimizações específicas
        vb.customize ['modifyvm', :id, '--cpuexecutioncap', '90']
        vb.customize ['modifyvm', :id, '--accelerate3d', 'off']
        vb.customize ['modifyvm', :id, '--audio', 'none']
      end

      # Setup comum
      node.vm.provision 'shell', inline: common_setup

      # Discos extras para Longhorn (apenas workers)
      if n[:disks] && !n[:disks].empty?
        n[:disks].each_with_index do |size_gb, i|
          disk_path = "./#{n[:name]}-disk#{i+1}.vdi"
          node.vm.provider 'virtualbox' do |vb|
            unless File.exist?(disk_path)
              vb.customize ['createhd', '--filename', disk_path, '--size', size_gb * 1024]
            end
            vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2 + i, '--device', 0, '--type', 'hdd', '--medium', disk_path]
          end
        end
      end

      # K3s específico por role
      if n[:k3s_role] == 'server'
        node.vm.provision 'shell', inline: <<-SHELL
          set -eux
          echo "Instalando k3s server em #{n[:name]}..."
          
          # Criar diretório para manifests estáticos
          mkdir -p /var/lib/rancher/k3s/server/manifests-staging
          
          # Copiar kube-vip manifest se for o primeiro control plane
          if [ "#{n[:name]}" == "prod-cp1" ] || [ "#{n[:name]}" == "stg-cp1" ]; then
            cp /vagrant/platform/kube-vip/kube-vip.yaml /var/lib/rancher/k3s/server/manifests-staging/
            # Ajustar VIP baseado no ambiente
            if [ "#{n[:name]}" == "stg-cp1" ]; then
              sed -i 's/192.168.56.200/192.168.56.210/' /var/lib/rancher/k3s/server/manifests-staging/kube-vip.yaml
            fi
          fi
          
          INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=#{K3S_VERSION} /usr/local/bin/k3s server \\
            --cluster-init \\
            --tls-san #{n[:k3s_vip]} \\
            --node-ip #{n[:ip]} \\
            --write-kubeconfig-mode 644 \\
            --disable traefik \\
            --disable servicelb &
          
          # Aguardar k3s estar pronto
          timeout=120
          while [ $timeout -gt 0 ]; do
            if [ -f /etc/rancher/k3s/k3s.yaml ]; then
              echo "K3s server pronto!"
              break
            fi
            echo "Aguardando k3s server... ($timeout)"
            sleep 2
            timeout=$((timeout-2))
          done
          
          # Aguardar API estar respondendo
          timeout=120
          while [ $timeout -gt 0 ]; do
            if curl -k -s https://#{n[:ip]}:6443/ping >/dev/null 2>&1; then
              echo "API server pronto!"
              break
            fi
            echo "Aguardando API server... ($timeout)"
            sleep 2
            timeout=$((timeout-2))
          done
        SHELL
      else
        node.vm.provision 'shell', inline: <<-SHELL
          set -eux
          echo "Aguardando server #{n[:k3s_server_ip]} estar pronto..."
          
          # Aguardar servidor estar acessível
          timeout=180
          while [ $timeout -gt 0 ]; do
            if curl -k -s https://#{n[:k3s_server_ip]}:6443/ping >/dev/null 2>&1; then
              echo "Server detectado, conectando agent..."
              break
            fi
            echo "Aguardando server... ($timeout)"
            sleep 3
            timeout=$((timeout-3))
          done
          
          echo "Instalando k3s agent em #{n[:name]}..."
          INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=#{K3S_VERSION} /usr/local/bin/k3s agent \\
            --server https://#{n[:k3s_server_ip]}:6443 \\
            --token #{K3S_TOKEN} \\
            --node-ip #{n[:ip]}
        SHELL
      end
    end
  end
end

