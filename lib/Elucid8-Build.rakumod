use RakuDoc::Render;
use RakuDoc::To::HTML;
use RakuConfig;
use File::Directory::Tree;
use PrettyDump;

constant NAV_DIR is export = 'assets';

class Elucid8::Processor is HTML::Processor {
    has @.pre-process-callables;
    has @.post-process-callables;
    has $!file-data-name;
    has %.file-data;              #| information about rendered files
                                  #| made available to all plugins
                                  #| it is initialise from a file when the build
                                  #| class is instantiated
    submethod TWEAK ( :$!file-data-name ) {
        %!file-data = EVALFILE $!file-data-name if $!file-data-name.IO ~~ :e & :f;
        self.templates.data<file-data> := %!file-data;
    }
    #| a method to initialise plugins before processing begins
    #| each Callable requires the lang and the filename
    #| the website root is immune to pre-processing
    method pre-process( $lang, $fn, $ast ) {
        return unless $lang;
        .( self, $lang, $fn, $ast ) for @!pre-process-callables
    }
    #| process a file after it has been fully rendered
    #| Not to be confused with post-all-content callables which are called
    #| by language after ALL content files are processed
    #| the website root landing page is immune to post-processing
    method post-process( $final ) {
        %!file-data<current><toc> = self.current.toc.elems ?? self.current.toc.Array !! [];
        %!file-data<current><index> = self.current.index.elems ?? self.current.index !! {};
        # allow for other plugins to affect file-data
        my $rendered = $final;
        for @!post-process-callables {
            $rendered = .( self, $rendered )
        }
        %!file-data<current>:delete; # discard now
        $rendered
    }
}

class Elucid8::Engine is RakuDoc::To::HTML {
    has $!rdp;              #| RakuDoc Process instance
    has %!config;           #| to contain the site's config data
    has $!f;                #| force flag - render all files from scratch
    has $!src;              #| the source directory
    has $!to;               #| where rendered files are stored
    has $!canonical;        #| the canonical human language
    has %!sources;          #| data about all source files in !src
    has $!file-data-name;   #| name where file data is stored
    has $!landing-page;     #| name of file(s) served when only route is visible
    has $!landing-source;   #| content of route landing file to over-ride auto
    has @!derived-langs;    #| list of languages in !src other than canonical
    has @!withs;            #| files to be rendered when restricted
    has %!glues;            #| glue files and their order
    has @!post-all-content-files; #| callables that operate after all content files have been processed
    has @!post-all-files; #| callables that operate after all content & glue files have been processed

    submethod TWEAK( :%!config, :$!f ) {
        $!src = %!config<sources>;
        $!to = %!config<publication>;
        $!canonical = %!config<canonical>;
        $!file-data-name = %!config<misc> ~ '/' ~ %!config<file-data-name>;
        $!landing-page = %!config<landing-page>;
        $!rdp = Elucid8::Processor.new(:output-format<html>, :$!file-data-name);
        $!rdp.add-templates( RakuDoc::To::HTML.new.html-templates, :source<RakuDoc::To::HTML>);
        $!rdp.add-plugins( %!config<plugins>.list );
        # for each plugin, check whether plugin-options are defined in the site config for the plugin
        # add them to the plugin's work-space, over-writing default ones
        my %d := $!rdp.templates.data;
        for %d.keys -> $wkspc {
            next unless %!config<plugin-options>{$wkspc}:exists;
            for %!config<plugin-options>{$wkspc}.kv { %d{$wkspc}{ $^a } = $^b }
        }
        # run callables for setup milestone - after all plugin enables, and using plugin-options
        for %!config<setup>.list -> ( :key($wkspc), :value($callable) ) {
            exit note "Cannot find a Callable called ｢$callable｣ in ｢$wkspc｣"
                unless %d{$wkspc}{$callable} ~~ Callable;
            %d{$wkspc}{$callable}.(%!config)
        }
        # callables for each milestone
        for %!config<pre-file-render>.list -> ( :key($wkspc), :value($callable) ) {
            exit note "Cannot find a Callable called ｢$callable｣ in ｢$wkspc｣"
                unless %d{$wkspc}{$callable} ~~ Callable;
            $!rdp.pre-process-callables.push: %d{$wkspc}{$callable}
        }
        for %!config<post-file-render>.list -> ( :key($wkspc), :value($callable) ) {
            exit note "Cannot find a Callable called ｢$callable｣ in ｢$wkspc｣"
                unless %d{$wkspc}{$callable} ~~ Callable;
            $!rdp.post-process-callables.push: %d{$wkspc}{$callable}
        }
        for %!config<post-all-content-files>.list -> ( :key($wkspc), :value($callable) ) {
            exit note "Cannot find a Callable called ｢$callable｣ in ｢$wkspc｣"
                unless %d{$wkspc}{$callable} ~~ Callable;
            @!post-all-content-files.push: %d{$wkspc}{$callable};
        }
        for %!config<post-all-files>.list -> ( :key($wkspc), :value($callable) ) {
            exit note "Cannot find a Callable called ｢$callable｣ in ｢$wkspc｣"
            unless %d{$wkspc}{$callable} ~~ Callable;
            @!post-all-files.push: %d{$wkspc}{$callable};
        }
        my @reserved = <ui-tokens css css-link js js-link>;
        # run the scss to css conversion after all plugins have been enabled
        # makes SCSS position independent
        if %d<SCSS>:exists {
            %d<SCSS><run-sass>.( $!rdp )
        }
        else { $!rdp.gather-flatten( 'css', :@reserved) }
        %d<UISwitcher><gather-ui-tokens>.( $!rdp, %!config );
        %d<UISwitcher><add-languages>.( %!config );
        $!rdp.gather-flatten(<css-link js-link js>, :@reserved );
    }

    method process-all {
        my $repo-url = "{%!config<misc>}/{%!config<repository-info-file>}";
        if $repo-url.IO ~~ :e & :d {
            %!sources = EVALFILE $repo-url;
            @!derived-langs = %!sources.keys.grep({ $_ ne $!canonical })
        }
        else {
            my @todo = $!src.IO.dir
                    .map({
                        # only save the over-riding landing page source
                        if .f && (.Str eq ( $!landing-page ~ '.rakudoc')) { $!landing-source = .slurp };
                        $_
                    })
                    .grep( *.d );
            # directories under sources must contain language content
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
                        )
                    }
                }
            }
        }
        exit note "No sources found in ｢$!src｣ and ｢$repo-url｣ not found" unless +%!sources;
        self.render-files;
        # post-processing saves the file data, so it does not need to happen here
    }

    method render-files {
        mktree $!to unless $!to.IO ~~ :e & :d;
        @!withs = %!config<with-only>.comb( / \S+ /);
        %!glues = %!config<glues>;
        my @canon-changes;
        my $content-changed = self.render-contents( $!canonical, @canon-changes, :canon );
        if $content-changed {
            .( $!rdp, $!canonical, $!to, %!config ) for @!post-all-content-files;
        }
        # this order is needed to trap changes in glues source with no change in content
        # first force function to run, then conserve what was in content change if True
        $content-changed = self.render-glues( $!canonical, @canon-changes, :canon )
            || $content-changed;
        for @!derived-langs -> $dl {
            $content-changed = self.render-contents( $dl, @canon-changes )
                || $content-changed;
            if $content-changed {
                .( $!rdp, $dl, $!to, %!config ) for @!post-all-content-files
            }
            $content-changed = self.render-glues( $dl, @canon-changes )
                || $content-changed;
        }
        if $content-changed {
            self.landing-page;
            dictionary-store( $!rdp.file-data, $!file-data-name);
            .( $!rdp, %!config ) for @!post-all-files
        }
        else { say 'Nothing has changed' }
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
            my $do-file = $!f || ($!rdp.file-data{$lang}{$short}:!exists)
                             || !$rendered-io.f
                             || %info<modified> > $rendered-io.modified
                             || ( $canon.not and $short (elem) @canon-changes )
                             ;
            %info<type> = 'primary';
            self.render-file($lang, $short, %info, $rendered-io) if $do-file;
            @canon-changes.push( $short ) if $canon and $do-file;
            $changes ||= $do-file
        }
        $changes
    }

    method render-glues( $lang, @canon-changes, Bool :$canon = False --> Bool ) {
        # render all glues if content changed.
        # TODO add dependency logic to only render glues if dependent content changed
        my $rdp := $!rdp;
        my Bool $changes = @canon-changes.elems > 0;
        # glue files typically have =ListFiles blocks
        my %listf := $rdp.templates.data<listfiles>;
        %listf<meta> = $rdp.file-data{$lang};
        for %!sources{ $lang }.pairs
            .grep({ any( %!glues.keys>>.starts-with( .key ) ) })
            .sort({ %!glues{ .key } }) # ensures that the order is according to the render order of glues
            .hash.kv
            -> $short, %info
            {
            my $rendered-io = $short.subst(/ ^ \w /, *.lc ); # substitution only needed for Raku documentation
            $rendered-io = "$!to/$lang/$rendered-io\.html".IO;
            with $rendered-io.dirname { mktree $_ unless .IO ~~ :e & :d }
            my $do-file = $!f                        # force flag is set
                        || $changes                  # a lower order glue file has been changed
                        || ($rdp.file-data{$lang}{$short}:!exists) # the file has not be rendered before
                        || !$rendered-io.f           # the rendered file does not exist
                        || %info<modified> > $rendered-io.modified # rendered file is older than source
                        ;
            %info<type> = 'glue';
            self.render-file($lang, $short, %info, $rendered-io) if $do-file;
            $changes ||= $do-file
        }
        $changes
    }
    #| create the website landing page, generate each time
    #| file data contains all rendered files
    #| Glues contains glue files in reverse order of appearance
    method landing-page {
        my $rdp := $!rdp;
        my %autof := $rdp.templates.data<AutoIndex>;
        #| list of arrays ordered by lang (canonical first), then its long name,
        #| then a list of glue files with fields ordered according to the reverse of the
        #| order in the plugins config
        my @glue-files = $rdp.file-data.pairs.grep(
            *.key.starts-with( $!canonical )
        ).map({
            [ .key,
                %!config<language-list>{ .key },
                (.value.pairs.grep({ .key eq any( %!glues.keys ) })
                            .sort({ %!glues{ .key } }).reverse
                            .map({ ( .value<title subtitle path>:p.Slip, :path( .key ) ).Hash })
                            ).Array
            ]
        }).Slip;
        for $rdp.file-data.pairs.grep({ .key ne $!landing-page })
            .grep({
                .key.starts-with( $!canonical ).not
                &&
                .key.starts-with( '*' ).not
            }) {
                @glue-files.push: [ .key,
                    %!config<language-list>{ .key },
                    (.value.pairs.grep({ .key eq any( %!glues.keys ) })
                                .sort({ %!glues{ .key } }).reverse
                                .map({ ( .value<title subtitle path>:p.Slip, :path( .key ) ).Hash })
                                ).Array
                ]
        }
        %autof<meta> = @glue-files;
        my $auto-rakudoc = qq:to/AUTO/;
        =begin rakudoc :!toc :!index
        =TITLE { %!config<landing-title> }
        =SUBTITLE { %!config<landing-subtitle> }
        =for AutoIndex :!toc
        =end rakudoc
        AUTO
        say "rendering website root $!landing-page";
        my Bool $got = $!landing-source.so;
        my $ast = ($got ?? $!landing-source !! $auto-rakudoc).AST;
        my $path = $got ?? "$!src/$!landing-page\.rakudoc" !! "\x1F916"; # robot face
        my $modified = $got ?? $path.IO.modified !! now;
        $rdp.pre-process( '*', $!landing-page, $ast );
        my $processed = $rdp.render(
            $ast,
            :source-data(%(
                name => $!landing-page,
                :$modified,
                :$path,
                language => $!canonical,
                home-page => "/$!landing-page",
        )), :pre-finalised);
        "$!to/$!landing-page\.html".IO.spurt($rdp.finalise);
        $rdp.file-data{'*'}{$!landing-page}{ .key } = .value for %(
            title => $processed.title,
            subtitle => $processed.subtitle ?? $processed.subtitle !! '',
            config => $processed.source-data<rakudoc-config>,
            lang => $!canonical,
            :type<glue>,
            :$modified,
        );
    }

    method render-file($language, $short, %info, $rendered-io) {
        say "rendering { %info<path> } to $rendered-io";
        my $path := %info<path>;
        my $ast = $path.slurp.AST;
        my $rdp := $!rdp;
        my $home-page = ($short.ends-with($!landing-page) ?? '/' !! "/$language/" ) ~ $!landing-page;
        $rdp.pre-process( $language, $short, $ast );
        my $processed = $rdp.render($ast, :source-data(%(
            name => $short,
            modified => %info<modified>,
            :$path,
            :$language,
            :$home-page,
            type => %info<type>,
        )), :pre-finalised);
        $rendered-io.spurt($rdp.finalise);
        $rdp.file-data{$language}{$short}{ .key } = .value for %(
            title => $processed.title,
            subtitle => $processed.subtitle ?? $processed.subtitle !! '',
            config => $processed.source-data<rakudoc-config>,
            modified => %info<modified>,
            type => $processed.source-data<rakudoc-config><type>:exists ?? $processed.source-data<rakudoc-config><type> !! %info<type>,
        ).pairs;
    }
}

proto sub MAIN(|) is export {*}

multi sub MAIN(
    :$config = 'config', #= localised config file
    Bool :install($)!,     #= install a config directory (if absent) from default values
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
    mktree %options<misc>;
    mktree %options<sources> ~ '/' ~ %options<canonical>;
}

multi sub MAIN(
    Bool :version(:$v)! #= Return version of distribution
) {
    say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v;
    say 'Rakudoc::Processor version: ', RakuDoc::Processor.^ver
};

multi sub MAIN(
    :$config = 'config',      #= localised config file
    Bool :force(:$f) = False, #= force complete rendering, otherwise only modified
    Str :$debug = 'None',     #= RakuAST-RakuDoc-Render debug list
    Str :$verbose = '',       #= RakuAST-RakuDoc-Render verbose parameter
    Str :$with-only,          #= only render these files, over-rides the config value
    Bool :$regenerate-from-scratch = False ,
                              #= delete any previous rendering and file data. Long process
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
    %config<with-only> = $_ with $with-only; # only over-ride if set
    # created deprecated url map
    unless (%config<publication> ~ '/' ~ NAV_DIR ~ '/deprecated-urls').IO ~~ :e & :f {
    # create the server-centric files for Caddy & Cro run-locally by default
        mktree %config<publication> ~ '/' ~ NAV_DIR;
        (%config<publication> ~ '/' ~ NAV_DIR ~ '/deprecated-urls').IO.spurt:
            %config<deprecated>.pairs.map({ .key.raku ~ ' ' ~ .value.raku }).join("\n")
    }
    if $regenerate-from-scratch {
        say "Rebuilding from scratch. May take a little longer.";
        my $ok = empty-directory %config<publication>;
        $ok = "{%config<misc>}/{%config<file-data-name>}".IO.unlink if $ok;
        exit note('Could not delete old build output') unless $ok
    }
    my Elucid8::Engine $engine .= new(:%config, :$f, :$debug, :$verbose );
    $engine.process-all
}
