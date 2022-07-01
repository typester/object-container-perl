# http://bit.ly/cpanfile
# http://bit.ly/cpanfile_version_formats
# cpm install -L extlib --with-recommends --with-test --with-configure --with-develop
requires 'perl', '5.006001';
requires 'strict';
requires 'warnings';
requires 'parent';
requires 'Class::Accessor::Fast';
requires 'Carp';
requires 'Exporter::AutoClean';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Base';
    requires 'Test::Requires';
    requires 'lib';
    requires 'FindBin';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.42';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod';
    requires 'Test::Spelling';
};
