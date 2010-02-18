use Test::More;
eval q{ use Test::Spelling };

plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(<DATA>);
set_spell_cmd("aspell -l en list");

my %ignore_files = (
    'lib/Object/Container/ja.pod' => 1,
);
my @pods = all_pod_files('lib');

plan tests => scalar @pods;

foreach my $pod(@pods){
    if(!$ignore_files{$pod}){
        pod_file_spelling_ok($pod);
    }
    else{
        pass "IGNORE: POD spelling for $pod";
    }
}
__DATA__
Daisuke
Murase
KAYAC


