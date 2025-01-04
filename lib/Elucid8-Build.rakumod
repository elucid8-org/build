use RakuDoc::Render;
use RakuDoc::To::HTML;
use RakuConfig;
use File::Directory::Tree;
use PrettyDump;

class Elucid8::Engine {
    has $!rdp;
    has %!config;
    has $!f;
    has $!src;
    has $!to;
    has $!canonical;
    has %!sources;
    has $!landing-page;
    has $!landing-source;
    has @!derived-langs;
    has %!file-data;
    has @!withs;
    has %!glues;

    submethod TWEAK( :$!rdp, :%!config, :$!f ) {
        $!src = %!config<sources>;
        $!to = %!config<destination>;
        $!canonical = %!config<canonical>;
        $!landing-page = %!config<landing-page>;
    }

    method process-all {
        my @todo = $!src.IO.dir
            .map({ # only save the over-riding landing page source
                if .f && (.Str eq ( $!landing-page ~ '.rakudoc' ) ) { $!landing-source = .slurp };
                $_
            })
            .grep( *.d ); # directories under sources must contain language content
        @!derived-langs = @todo.map( *.relative($!src) );
        exit note "No directory found corresponding to ｢$!canonical｣" unless
            $!canonical (elem) @!derived-langs;
        @!derived-langs .= grep({ $_ ne $!canonical });
        while @todo {
            for @todo.pop.dir -> $path {
                if $path.d {
                    @todo.push: $path;
                }
                else {
                    my $lang = $path.dirname.split('/').[1];
                    my $short = $path.relative($!src).IO.relative($lang).IO.extension('');
                    %!sources{$lang}{$short} = %(
                        :$path,
                        modified => $path.modified,
                        :$lang
                    )
                }
            }
        }
        exit note "No sources found in ｢$!src｣" unless +%!sources;
        %!file-data = EVALFILE 'file-data.rakuon' if 'file-data.rakuon'.IO ~~ :e & :f;
        self.render-files;
        self.store(%!file-data,'file-data.rakuon');
    }

    method render-files {
        mktree $!to unless $!to.IO ~~ :e & :d;
        @!withs = %!config<with-only>.comb( / \S+ /);
        %!glues = %!config<glues>;
        my @rendered-glues;
        my @canon-changes;
        my $content-changed = self.render-contents( $!canonical, @canon-changes, :canon );
        @rendered-glues.push: $!canonical => self.render-glues( $!canonical, @canon-changes, :canon, :$content-changed );
        for @!derived-langs {
            $content-changed = self.render-contents( $_, @canon-changes );
            @rendered-glues.push: $_ =>  self.render-glues( $_, @canon-changes, :$content-changed );
        }
        self.landing-page( @rendered-glues );
    }

    method render-contents( $lang, @canon-changes, Bool :$canon = False --> Bool ) {
        my $changes = False;
        my @withs := @!withs;
        for %!sources{ $lang }.pairs
            .grep({ @withs.elems == 0 or .key ~~ / @withs /})
            .grep({ none( %!glues.keys>>.starts-with( .key ) ) })
            .hash.kv
            -> $short, %info
            {
            with $short.IO.dirname { mktree "$!to/$lang/$_" unless "$!to/$lang/$_".IO ~~ :e & :d }
            my $rendered-io = "$!to/$lang/$short\.html".IO;
            my $do-file = $!f || (%!file-data{$lang}{$short}:!exists)
                             || !$rendered-io.f
                             || %info<modified> > $rendered-io.modified
                             || ( $canon.not and $short (elem) @canon-changes )
                             ;
            self.render-file($short, %info, $rendered-io) if $do-file;
            @canon-changes.push( $short ) if $canon and $do-file;
            $changes ||= $do-file
        }
        $changes
    }

    method render-glues( $lang, @canon-changes, Bool :$canon = False, Bool :$content-changed --> Array ) {
        my @withs := @!withs;
        my @rendered-glues;
        for %!sources{ $lang }.pairs
            .grep({ any( %!glues.keys>>.starts-with( .key ) ) })
            .grep({ @withs.elems == 0 or .key ~~ / @withs /})
            .sort({ %!glues{ .key } }) # ensures that the order is according to the render order of glues
            .hash.kv
            -> $short, %info
            {
            my %listf := $!rdp.templates.data<listfiles>;
            %listf<meta> = %!file-data{$lang};
            with $short.IO.dirname { mktree "$!to/$lang/$_" unless "$!to/$lang/$_".IO ~~ :e & :d }
            my $rendered-io = "$!to/$lang/$short\.html".IO;
            my $do-file = $!f || $content-changed
                             || (%!file-data{$lang}{$short}:!exists)
                             || !$rendered-io.f
                             || %info<modified> > $rendered-io.modified
                             || ( $canon.not and $short (elem) @canon-changes )
                             ;
            self.render-file($short, %info, $rendered-io) if $do-file;
            @canon-changes.push($short) if $canon and $do-file;
            @rendered-glues.push: %( ( %!file-data{$lang}<title subtitle>:p ).Slip, :rendered-to );
        }
        @rendered-glues
    }

    method landing-page( @glue-files ) {
        my %listf := $!rdp.templates.data<AutoIndex>;
        %listf<meta> = @glue-files;
        my $auto-rakudoc = qq:to/AUTO/;
        =begin rakudoc :!toc :!index
        =TITLE { %!config<landing-title> }
        =SUBTITLE { %!config<landing-subtitle> }
        =AutoIndex
        =end rakudoc
        AUTO
        say "rendering $!landing-page";
        my $ast = ($!landing-page ?? $!landing-page !! $auto-rakudoc).AST;
        my $path = $!landing-page ?? "$!src/$!landing-page\.rakudoc" !! "\x1F916"; # robot face
        my $modified = $!landing-page ?? $path.IO.modified !! now;
        my $processed = $!rdp.render(
            $ast,
            :source-data(%(
                name => $!landing-page,
                :$modified,
                :$path,
            language => $!canonical
        )), :pre-finalised);
        "$!to/$!landing-page\.html".spurt($!rdp.finalise);
        %!file-data{$!landing-page} = %(
            title => $processed.title,
            subtitle => $processed.subtitle ?? $processed.subtitle !! '',
            config => $processed.source-data<rakudoc-config>,
            lang => $!canonical
        );
    }

    method render-file($short, %info, $rendered-io) {
        say "rendering { %info<path> } to $rendered-io";
        my $path := %info<path>;
        my $lang := %info<lang>;
        my $processed = $!rdp.render($path.slurp.AST, :source-data(%(
            name => $short,
            modified => %info<modified>,
            :$path,
            language => $lang
        )), :pre-finalised);
        $rendered-io.spurt($!rdp.finalise);
        %!file-data{$lang}{$short} = %(
            title => $processed.title,
            subtitle => $processed.subtitle ?? $processed.subtitle !! '',
            config => $processed.source-data<rakudoc-config>
        );
    }
    method store( %dict, $fn ) {
        my $pretty = PrettyDump.new;
        my $pair-code = -> PrettyDump $pretty, $ds, Int:D :$depth = 0 --> Str {
            [~]
                '｢', $ds.key, '｣',
                ' => ',
                $pretty.dump: $ds.value, :depth(0)

            };

        my $hash-code = -> PrettyDump $pretty, $ds, Int:D :$depth = 0 --> Str {
            my $longest-key = $ds.keys.max: *.chars;
            my $template = "%-{2+$depth+1+$longest-key.chars}s => %s";

            my $str = do {
                if @($ds).keys {
                    my $separator = [~] $pretty.pre-separator-spacing, ',', $pretty.post-separator-spacing;
                    [~]
                        $pretty.pre-item-spacing,
                        join( $separator,
                            grep { $_ ~~ Str:D },
                            map {
                                /^ \t* '｢' .*? '｣' \h+ '=>' \h+/
                                    ??
                                sprintf( $template, .split: / \h+ '=>' \h+  /, 2 )
                                    !!
                                $_
                                },
                            map { $pretty.dump: $_, :depth($depth+1) }, $ds.pairs
                            ),
                        $pretty.post-item-spacing;
                    }
                else {
                    $pretty.intra-group-spacing;
                    }
                }

            "\{$str}"
            }
        $pretty.add-handler: 'Pair', $pair-code;
        $pretty.add-handler: 'Hash', $hash-code;
        $fn.IO.spurt: $pretty.dump(%dict);
    }
}

proto sub MAIN(|) is export {*}

multi sub MAIN(
    :$config = 'config', #| local config file
    Bool :$install!,     #| install a config directory (if absent) from default values
) {
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
    mktree %options<sources> ~ '/' ~ %options<canonical>
}

multi sub MAIN(
    Bool :version(:$v)! #= Return version of distribution
) { say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v };

multi sub MAIN(
    :$config = 'config',      #| local config file
    Bool :force(:$f) = False, #| force complete rendering, otherwise only modified
    Str :$debug = 'None',     #| RakuAST-RakuDoc-Render debug list
    Str :$verbose = '',        #| RakuAST-RakuDoc-Render verbose parameter
) {
    my %config;
    if $config.IO ~~ :e & :d {
        %config = get-config(:path( $config ))
    }
    else {
        if $config eq 'config' {
            exit note "Has another config directory been created? \
            If so run ｢{ $*PROGRAM.basename } --config=«installed config directory»｣\
            Or to install run ｢{ $*PROGRAM.basename } --install｣"
        }
        else { exit note "Cannot proceed without directory ｢$config｣. Try runing ｢{ $*PROGRAM.basename } --config=$config --install｣." }
    }
    my $rdp = RakuDoc::To::HTML.new.rdp;
    $rdp.debug( $debug );
    $rdp.debug( $verbose );
    $rdp.add-plugins( 'RakuDoc::Plugin::HTML::' «~« %config<rakuast-rakudoc-plugins>.list );
    $rdp.add-plugins( 'Elucid8::Plugin::HTML::' «~« %config<plugins>.list );
    # for each plugin, check whether there are plugin-options for the plugin
    # add them to the work-space
    for $rdp.templates.data.keys -> $wkspc {
        next unless %config<plugin-options>{$wkspc}:exists;
        for %config<plugin-options>{$wkspc}.kv { $rdp.templates.data{$wkspc}{ $^a } = $^b }
    }
    my @reserved = <ui-tokens css css-link js js-link>;
    # run the scss to css conversion after all plugins have been enabled
    # makes SCSS position independent
    if $rdp.templates.data<SCSS>:exists {
        $rdp.templates.data<SCSS><run-sass>.( $rdp )
    }
    else { $rdp.gather-flatten( 'css', :@reserved) }
    $rdp.templates.data<UISwitcher><gather-ui-tokens>.( $rdp, %config );
    $rdp.gather-flatten(<css-link js-link js>, :@reserved );
    my Elucid8::Engine $engine .= new(:$rdp, :%config, :$f );
    $engine.process-all
}