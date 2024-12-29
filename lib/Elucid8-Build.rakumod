use v6.d;
use RakuDoc::Render;
use RakuConfig;

proto sub MAIN(|) is export {*}

multi sub MAIN(
    :$config = 'config',     #| local config file
    Bool :$install = False,  #| install a config directory (if absent) from default values
) {
    unless $config.IO ~~ :e & :d {
        if $install { elucid8-install($config) }
        elsif $config eq 'config' {
            exit note "Has another config directory been created? \
            If so run ｢{ $*PROGRAM.basename } --config=«installed config directory»｣\
            Or to install run ｢{ $*PROGRAM.basename } --install｣"
        }
        else { exit note "Cannot proceed without directory ｢$config｣. Try runing ｢{ $*PROGRAM.basename } --config=$config --install｣." }
    }
}

multi sub MAIN(
    Bool :version(:$v)! #= Return version of distribution
) { say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v };

sub elucid8-install( $config ) {
    my $path = $config.IO.mkdir;
    my $resource;
    my @defaults = <01-base.raku 02-plugins.raku 03-plugin-options.raku>;
    for @defaults {
        $resource := %?RESOURCES{ "config/$_" };
        indir $path, {.IO.spurt( $resource.slurp(:close) )}
    }
    my %options = get-config(:$path);
    # create the necessary directory structure from the config
    indir $path, { %options<sources>.IO.mkdir };
    indir $path, { %options<L10N>.IO.mkdir };
    indir $path ~ '/' ~  %options<sources>, { %options<canonical>.IO.mkdir };
}