# Set up authorized_keys file for root account
#
# @summary
#   Set up authorized_keys file for root account
#
# @example
#   include openssh::keys
#
# @param sshkey_user
#   The user account in which the SSH key should be installed. The resource
#   will autorequire this user if it is being managed as a user resource.
#
# @param authorized
#   If provided - it is exact list of SSH public keys to be added into user
#   root account
#   All other settings will be ignored except sshkey_dir
#
# @param sshkey
#   The public key itself; generally a long string of hex characters. The key
#   attribute may not contain whitespace.
#
#   Make sure to omit the following in this attribute (and specify them in
#   other attributes):
#   - Key headers, such as ‘ssh-rsa’ — put these in the type attribute.
#   - Key identifiers / comments, such as ‘joe@joescomputer.local’ — put these
#     in the name attribute/resource title.
#
# @param sshkey_name
#   The SSH key comment. This can be anything, and doesn’t need to match the
#   original comment from the .pub file.
#
#   Due to internal limitations, this must be unique across all user accounts;
#   if you want to specify one key for multiple users, you must use a different
#   comment for each instance.
#
# @param sshkey_type
#   The encryption type used.
#   Allowed values:
#     ssh-dss
#     ssh-rsa
#     ecdsa-sha2-nistp256
#     ecdsa-sha2-nistp384
#     ecdsa-sha2-nistp521
#     ssh-ed25519
#     dsa
#     ed25519
#     rsa
#
# @param sshkey_target
#   The absolute filename in which to store the SSH key. This property is
#   optional and should be used only in cases where keys are stored in a non-
#   standard location, for instance when not in ~user/.ssh/authorized_keys
#
# @param sshkey_options
#   Key options; see sshd(8) for possible values. Multiple values should be
#   specified as an array.
#
class openssh::keys (
  Optional[
    Array[
      Struct[{
        type => String,
        key  => String,
        name => String,
      }]
    ]
  ]       $authorized       = undef,
  Optional[
    Array[
      Struct[{
        type => String,
        key  => String,
        name => String,
      }]
    ]
  ]       $custom_ssh_keys  = $authorized,
  Optional[Stdlib::Base64]
          $sshkey           = undef,
  Enum['present', 'absent']
          $sshkey_ensure    = present,
  Boolean $sshkey_propagate = false,
  Optional[String]
          $sshkey_group     = $openssh::sshkey_group,
  String  $sshkey_user      = $openssh::sshkey_user,
  Openssh::KeyType
          $sshkey_type      = $openssh::sshkey_type,
  Optional[String]
          $sshkey_name      = $openssh::sshkey_name,
  Stdlib::Unixpath
          $sshkey_dir       = $openssh::sshkey_dir,
  Stdlib::Unixpath
          $sshkey_target    = $openssh::sshkey_target,
  Array[String]
          $sshkey_options   = $openssh::sshkey_options,

) {
  $key_owner_group = $sshkey_group ? {
    String  => $sshkey_group,
    default => $sshkey_user,
  }

  file { $sshkey_dir:
    ensure => directory,
    owner  => $sshkey_user,
    group  => $key_owner_group,
    mode   => '0700',
  }

  if $custom_ssh_keys {
    file { "${sshkey_dir}/authorized_keys":
      ensure  => present,
      content => template('openssh/authorized_keys.erb'),
      require => File[$sshkey_dir],
    }

    @@sshkey { "${::fqdn}_root_known_host":
      host_aliases => [$::hostname, $::fqdn, $::ipaddress],
      key          => $::ssh['ecdsa']['key'],
      target       => '/root/.ssh/known_hosts',
      type         => $::ssh['ecdsa']['type'],
    }
  }
  elsif $sshkey_name {
    openssh::auth_key { $sshkey_name:
      sshkey_ensure    => $sshkey_ensure,
      sshkey_user      => $sshkey_user,
      sshkey_type      => $sshkey_type,
      sshkey_target    => $sshkey_target,
      sshkey_options   => $sshkey_options,
      sshkey_propagate => $sshkey_propagate,
      sshkey           => $sshkey,
      sshkey_export    => true,
      require          => File[$sshkey_dir],
    }
  }
}
