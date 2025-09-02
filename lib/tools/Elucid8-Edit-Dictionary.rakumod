use v6.d;
use RakuDoc::Render;
use RakuConfig;

use Cro::WebApp::Template;
use Cro::Server;
use Cro::Router;

proto sub MAIN(|) is export {*}

multi sub MAIN(
        Bool :version(:$v)! #= Return version of distribution
               ) {
    say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v;
    say 'Rakudoc::Processor version: ', RakuDoc::Processor.^ver
};

multi sub MAIN(
        :$config = 'config' #= localised config file
    )  {
    my %config;
    if $config.IO ~~ :e & :d {
        %config = get-config(:path( $config ))
    }
    else {
        if $config eq 'config' {
            exit note "Has another config directory been created?"
        }
        else { exit note "Cannot proceed without directory ｢$config｣. Try runing ｢elucid8-build --config=$config --install｣  ." }
    }
    my $dict-fn = %config<misc> ~ '/' ~ %config<ui-dictionary>;
    exit note "$dict-fn does not exist" unless ($dict-fn.IO ~~ :e & :f).so;
    my $new-fn = %config<misc> ~ '/new-' ~ %config<ui-dictionary>;
    #| contains the current (perhaps edited) versions of cannonical keys and other language keys
    my %dict = EVALFILE( $dict-fn );
    my $canonical = %config<canonical>;
    my @d-langs = %dict.keys.grep({  $_ ne $canonical  });
    my Set $d-canon-keys .= new: %dict{$canonical}.keys;
    # get the keys defined in each of the configured plugins
    $rdp = Elucid8::Processor.new;
    $rdp.add-plugins( %config<plugins>.list );
    # for each plugin, check whether plugin-options are defined in the site config for the plugin
    my %d := $rdp.templates.data;
    my %ui-tokens = %d.pairs
            .grep({ .value ~~ Associative })
            .grep({ .value.<ui-tokens> ~~ Associative })
            .map(  *.value.<ui-tokens>.Slip )
            .map({ .key => .value.Str })
            .hash;
    my @all-tokens;
    for %ui-tokens.kv -> $k, $v {
        @all-tokens.push: $k;
        unless %dict{$k}:exists {
            %dict{$k} = $v;
            $d-canon-keys{$k}++;
        }
    }
    # find keys in %dict that are not in %ui-tokens
    my Set $redundant =  $d-canon-keys (-) %ui-tokens.keys;
    # create initial page to be served
    my $page;
}
