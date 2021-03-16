# @summary Install and configure the MySQL orchestrator server
#
# Install and configure the MySQL orchestrator server
#
# @example
#   include mysql_orchestrator::server
class mysql_orchestrator::server (
  Array[String] $preq_pkgs,
  String        $rpm_url,
  String        $cli_rpm_url,
  String        $conf_json,
  String        $raft_port,
  Hash          $raft_subnets,
  String        $service_port,
  Hash          $service_subnets,
) {

  # INSTALL orchestrator PACKAGES
  ensure_packages($preq_pkgs, {
    'ensure' => 'present',
  })
  ensure_packages('orchestrator', {
    'ensure'   => 'latest',
    'provider' => 'rpm',
    'source'   => $rpm_url,
    'notify'   => 'Service["orchestrator"]',
  })
  ensure_packages('orchestrator-cli', {
    'ensure'   => 'latest',
    'provider' => 'rpm',
    'source' => $cli_rpm_url,
  })
  include ::mysql_orchestrator::client

  Package[$preq_pkgs] -> Package['orchestrator'] -> Package['orchestrator-cli'] -> Package['orchestrator-client']

  # CONFIGURE orchestrator
  file { '/etc/orchestrator.conf.json':
    ensure  => 'file',
    content => $conf_json,
    mode    => '0640',
    owner   => 'root',
    group   => 'root',
    notify  => Service['orchestrator'],
  }

  # SETUP SCRIPTS AND CRONS

  # START SERVICE
  service { 'orchestrator':
    ensure  => 'running',
    enable  => 'true',
    require => [
      Package['orchestrator'],
      File['/etc/orchestrator.conf.json'],
    ]
  }

  # SETUP FIREWALL
  $raft_subnets.each | $location, $source_cidr |
  {
    firewall { "200 ALLOW orchestrator raft ON ${raft_port} FROM ${location}":
      proto  => tcp,
      dport  => $raft_port,
      source => $source_cidr,
      action => accept,
    }
  }
  $service_subnets.each | $location, $source_cidr |
  {
    firewall { "220 ALLOW orchestrator SERVICE ON ${service_port} FROM ${location}":
      proto  => tcp,
      dport  => $service_port,
      source => $source_cidr,
      action => accept,
    }
  }

}
