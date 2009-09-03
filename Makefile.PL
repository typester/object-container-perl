use inc::Module::Install;
name 'Object-Container';
all_from 'lib/Object/Container.pm';

requires 'Any::Moose' => '0.10';
requires 'Class::Singleton';
requires 'Exporter::AutoClean';

test_requires 'Test::More';
use_test_base;
author_tests 'xt';

auto_include;
auto_set_repository;

WriteAll;
