use inc::Module::Install;
name 'Object-Container';
all_from 'lib/Object/Container.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Singleton';
requires 'Data::Util';
requires 'Exporter::AutoClean';
requires 'parent';

test_requires 'Test::More' => '0.88';
use_test_base;
author_tests 'xt';

auto_include;
auto_set_repository;

WriteAll;
