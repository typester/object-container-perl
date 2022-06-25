use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Object-Container',
    module_name         => 'Object::Container',
    dist_version_from   => 'lib/Object/Container.pm',
    add_to_cleanup      => [ 'Object-Container-*' ],
    no_index => {
        directory => [ 't', 'xt', 'share' ],
    },
    meta_merge     => {
      resources => {
        repository  => 'https://github.com/typester/object-container-perl/',
        bugtracker  => 'https://github.com/typester/object-container-perl/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 0, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();