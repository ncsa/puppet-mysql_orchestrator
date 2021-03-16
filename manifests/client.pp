# @summary Install and configure the MySQL orchestrator client
#
# Install and configure the MySQL orchestrator client
#
# @example
#   include mysql_orchestrator::client
class mysql_orchestrator::client (
  Array[String] $preq_pkgs,
  String        $rpm_url,
  String        $profile_csh_content,
  String        $profile_sh_content,
) {

  # INSTALL orchestrator-client PACKAGES
  ensure_packages($preq_pkgs, {'ensure' => 'present'})
  ensure_packages('orchestrator-client', {'ensure' => 'latest', 'provider' => 'rpm', 'source' => $rpm_url, })

  Package[$preq_pkgs] -> Package['orchestrator-client']

  File {
    ensure => 'file',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/profile.d/orchestrator.csh':
    content => $profile_csh_content,
  }
  file { '/etc/profile.d/orchestrator.sh':
    content => $profile_sh_content,
  }

}
