use RakuDoc::Render;
use RakuDoc::To::HTML;
use RakuConfig;
use File::Directory::Tree;

proto sub MAIN(|) is export {*}

multi sub MAIN(
    :$config = 'config',      #| local config file
    Bool :$install = False,   #| install a config directory (if absent) from default values
    Bool :force(:$f) = False, #| force complete rendering, otherwise only modified
    Str :$debug = 'None',     #| RakuAST-RakuDoc-Render debug list
) {
    my %config;
    if $config.IO ~~ :e & :d {
        %config = get-config(:path( $config ))
    }
    else {
        if $install { %config = elucid8-install($config) }
        elsif $config eq 'config' {
            exit note "Has another config directory been created? \
            If so run ｢{ $*PROGRAM.basename } --config=«installed config directory»｣\
            Or to install run ｢{ $*PROGRAM.basename } --install｣"
        }
        else { exit note "Cannot proceed without directory ｢$config｣. Try runing ｢{ $*PROGRAM.basename } --config=$config --install｣." }
    }
    my $src = %config<sources>;
    my $to = %config<destination>;
    my $rdp = RakuDoc::To::HTML.new.rdp;
    my @reserved = <ui-tokens css css-link js js-link>;
    $rdp.debug( $debug );
    $rdp.add-plugins( 'RakuDoc::Plugin::HTML::' «~« %config<rakuast-rakudoc-plugins>.list );
    $rdp.add-plugins( 'Elucid8::Plugin::HTML::' «~« %config<plugins>.list );
    # for each plugin, check whether there are plugin-options for the plugin
    # add them to the work-space
    for $rdp.templates.data.keys -> $wkspc {
        next unless %config<plugin-options>{$wkspc}:exists;
        for %config<plugin-options>{$wkspc}.kv { $rdp.templates.data{$wkspc}{ $^a } = $^b }
    }
    # run the scss to css conversion after all plugins have been enabled
    # makes SCSS position independent
    if $rdp.templates.data<SCSS>:exists {
        $rdp.templates.data<SCSS><run-sass>.( $rdp )
    }
    else { $rdp.gather-flatten( 'css', :@reserved) }
    $rdp.templates.data<UISwitcher><gather-ui-tokens>.( $rdp, %config );
    $rdp.gather-flatten(<css-link js-link js>, :@reserved );
    my %sources;
    my @todo = $src.IO;
    while @todo {
        for @todo.pop.dir -> $path {
            if $path.d {
                @todo.push: $path;
            }
            else {
                %sources{$path.relative($src).IO.extension('')} = %(
                    :$path,
                    modified => $path.modified
                )
            }
        }
    }
    exit note "No sources found in ｢$src｣" unless +%sources;
    mktree $to unless $to.IO ~~ :e & :d;
    render-files(%sources, $to, $f, $rdp, %config)
}

multi sub MAIN(
    Bool :version(:$v)! #= Return version of distribution
) { say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v };

sub render-files (%sources, $to, $f, $rdp, %config) {
    my %file-data;
    %file-data = EVALFILE 'file-data.rakuon' if 'file-data.rakuon'.IO ~~ :e & :f;
    my $changes = False;
    for %sources.kv -> $short, %info {
    say "@ $?LINE short $short test ",so $short.IO.stem ~~ %config<last>.list.any ;
        next if $short.IO.stem ~~ %config<last>.list.any;
        my $rendered-io = "$to/$short\.html".IO;
        my $do-file = $f
            or (%file-data{$short}:!exists)
            or ($rendered-io !~~ :e & :f or %info<modified>.Int > $rendered-io.modified);
        render-file($rdp, $to, $short, %info, $rendered-io, %file-data) if $do-file;
        $changes |= $do-file;
    }
    # No changes to content files means the site-
    my %listf := $rdp.templates.data<listfiles>;
    %listf<meta> = %file-data;
    for %sources.pairs.grep({ .key.IO.stem ~~ %config<last>.list.any }).kv -> $short, %info {
        my $rendered-io = "$to/$short\.html".IO;
        render-file($rdp, $to, $short, %info, $rendered-io, %file-data)
    }
    'file-data.rakuon'.IO.spurt: %file-data.raku;
}
sub render-file($rdp, $to, $short, %info, $rendered-io, %file-data) {
    say "rendering { %info<path> } to $rendered-io";
    my $path := %info<path>;
    my $processed = $rdp.render($path.slurp.AST, :source-data(%(
        name => $short,
        modified => %info<modified>,
        :$path,
    )), :pre-finalised);
    with $short.IO.dirname { mktree "$to/$_" unless "$to/$_".IO ~~ :e & :d }
    $rendered-io.spurt($rdp.finalise);
    %file-data{$short} = %(
        title => $processed.title,
        subtitle => $processed.subtitle ?? $processed.subtitle !! 'No description',
        config => $processed.source-data<rakudoc-config>,
    );
}

sub elucid8-install( $config --> Hash ) {
    my $path = $config.IO.mkdir;
    my $resource;
    my @defaults = <01-base.raku 02-plugins.raku 03-plugin-options.raku>;
    for @defaults {
        $resource := %?RESOURCES{ "config/$_" };
        indir $path, {.IO.spurt( $resource.slurp(:close) )}
    }
    my %options = get-config(:$path);
    # create the necessary directory structure from the config
    mktree %options<L10N>;
    mktree %options<sources> ~ '/' ~ %options<canonical> ;
    %options
}