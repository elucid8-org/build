use experimental :rakuast;
use RakuDoc::Render;
use RakuDoc::Processed;
use nqp;
use PrettyDump;
use Elucid8-Build;

grammar DefinitionHeading {
    token operator { infix | prefix | postfix | circumfix | postcircumfix | listop }
    token routine { sub | method | term | routine | submethod | trait }
    token syntax { twigil | constant | variable | quote | declarator }
    token subkind { <routine> | <syntax> | <operator> }
    token inner-s { <-[>]>+  }
    token inner-d { <-[»]>+  }
    token embedded { 'C<' <inner-s> '>' | 'C«' <inner-d> '»'}
    token name { <embedded> | .+ }
    token single-name { <embedded> | \S+ }
    token the-foo-infix {
        ^ \s* [T | t]'he' \s <single-name> \s <subkind> \s* $
    }
    rule infix-foo { ^\s*<subkind> <name>\s*$ }
    rule TOP { <the-foo-infix> | <infix-foo>  }
}
class DefinitionHeadingActions {
    has Str  $.dname     = '';
    has      $.dkind     = '';
    has Str  $.dsubkind  = '';

    method name($/) {
        $!dname = $/.Str.trim;
        $!dname = $_ with $<embedded>.made;
    }
    method single-name($/) {
        $!dname = $/.Str.trim;
        $!dname = $_ with $<embedded>.made;
    }
    method embedded($/) {
        make $/<inner-s>.Str.trim if $/<inner-s>;
        make $/<inner-d>.Str.trim if $/<inner-d>;
    }
    method subkind($/) {
        $!dsubkind = $/.Str.trim;
    }
    method operator($/) {
        $!dkind     = 'operator';
    }
    method routine($/) {
        $!dkind     = 'routine';
    }
    method syntax($/) {
        $!dkind     = 'syntax';
    }
}
class Elucid8::Plugin::HTML::SiteData {
    has %.fd;
    #| data from file data and refreshed when other files are rendered
    has %.definitions;
    has %.config =
        :name-space<SiteData>,
        :version<0.1.0>,
        :license<Artistic-2.0>,
        :credit<finanalyst>,
        :authors<finanalyst>,
        :%!definitions,
        gen-composites => -> $rdp, $lang, $to { self.generate-composites( $rdp, $lang, $to ) },
        initialise => -> $rdp, $lang, $fn, $ast { self.initialise( $rdp, $lang, $fn, $ast ) },
    ;

    method enable( RakuDoc::Processor:D $rdp ) {
        $rdp.add-data( %!config<name-space>, %!config );
    }
    #| routine is only called for files that are being rendered
    #| data from files not rendered - if any - is kept
    #| do not preprocess webroot
    method initialise( $rdp, $lang, $fn, $ast ) {
        $rdp.file-data{$lang} = %() unless $rdp.file-data{$lang}:exists;
        $rdp.file-data{$lang}{$fn} = %() unless $rdp.file-data{$lang}{$fn}:exists;
        $rdp.file-data{$lang}{$fn}<xtrk-targs> = SetHash.new;
        $rdp.file-data{$lang}{$fn}<defns> = %();
        $rdp.file-data<current> := $rdp.file-data{$lang}{$fn};
        %!fd := $rdp.file-data{ $lang }{ $fn };
        return if $lang eq '*';
        my $xtr-trgt = "$lang#$fn#000";
        my $consuming = False;
        my $level;
        my $snippet;
        for $ast.rakudoc.head.paragraphs.list -> $node {
            my Bool $is-head = ($node ~~ RakuAST::Doc::Block) && ($node.type eq 'head');
            next unless $consuming || $is-head ;
            if $consuming {
                # check for end consuming condition
                if $is-head && $node.level <= $level {
                    $consuming = False;
                    $level = 0;
                    %!fd<defns>{$xtr-trgt}<snip> = $snippet;
                }
                else {
                    if $is-head {
                        my $n-head = $node.clone;
                        $n-head.set-level( $n-head.level - $level + 1 ); # change the heading level
                        $snippet.add-paragraph( $n-head )
                    }
                    else { $snippet.add-paragraph( $node.clone ) }
                }
            }
            else { # check for starting condition
                my DefinitionHeadingActions $actions .= new;
                my $signif = DefinitionHeading.parse( $node.Str.trim, :$actions );
                if $signif {
                    %!fd<defns>{ ++$xtr-trgt } = %(
                        :name($actions.dname),
                        :kind($actions.dkind),
                        :subkind($actions.dsubkind),
                    );
                    my $n-head = $node.clone;
                    $n-head.set-level(2) ; # change the heading level
                    $snippet = RakuAST::Doc::Block.new( :type<section>, :paragraphs( $n-head, ) );
                    $consuming = True;
                    $level = $node.level;
                }
            }
        }
        # add last snip in file if snip runs to end of file
        %!fd<defns><$xtr-t><snip> = $snippet if $consuming;
    }

    #| originally, Raku documentation was generated using Documentable
    #| before some chars were allowed as URLs
    #| links outside the site may still point to documentation using the
    #| Documentable workaround. So, these are coded as aliases to be
    #| substituted with internally generated filenames
    #| To overcome file-system limitations on what filenames may contain
    #| the filename generated is hashed and the file stored in assets
    sub good-name($name is copy --> Str) is export {
        # Documentable substitutes Filesystem unsafe chars with
        # / => $SOLIDUS
        # % => $PERCENT_SIGN
        # ^ => $CIRCUMFLEX_ACCENT
        # # => $NUMBER_SIGN
        # So, we need to generate psuedo-urls that will also point to hashed files using
        # the same algorithm as Documentable. If these are used in anchors in sources, they
        # will be correctly mapped as well.
        my @badchars = ["/", "^", "%"];
        my @goodchars = @badchars
            .map({ '$' ~ .uniname })
            .map({ .subst(' ', '_', :g) });
        # Collection has already escaped names, so de-HTML-escape name
        $name .= trans(qw｢ &lt; &gt; &amp; &quot; ｣ => qw｢ <    >    &   " ｣);
        $name .= subst(@badchars[0], @goodchars[0], :g);
        $name .= subst(@badchars[1], @goodchars[1], :g);
        # if it contains escaped sequences (like %20) we do not
        # escape %
        if (!($name ~~ /\%<xdigit> ** 2/)) {
            $name .= subst(@badchars[2], @goodchars[2], :g);
        }
        $name;
    }
    method generate-composites( $rdp, $lang, $to ) {
        #| create a directory for the composites
        my $prefix = NAV_DIR;
        #| data register
        my %templates := $rdp.templates;
        #| workspaces
        my %workspc := %templates.data;
        #| get the files by language
        %!fd := $rdp.file-data{ $lang };
        my %things := %!definitions;
        #| each of the categories we want to group file definitions by
        %things = %( routine => {}, syntax => {}, operator => {} );
        #| url mapping for HTML server 'external ref' => 'website name'
        my %url-maps;
        #| aliases for targets to be checked for internal link consistency
        my %aliases;
        for %!fd.kv -> $fn, %info {
            next unless %info<defns>.elems;
            #| caption to be associated with file name
            my $src-caption = %info<title> ~ "  ( $fn )";
            for %info<defns>.kv -> $targ-in-fn, %attrs {
                with %attrs {
                    next unless .<name>:exists; # skip X<> header sections
                    # strip off everything after first space or equivalent
                    my $sh-name = .<name>.subst(/ [ '_' | '-' | '()' ] .* $ /, '');
                    %things{ .<kind> }{ $sh-name }.push: %(
                        :name( .<name> ),
                        :subkind( .<subkind> ),
                        :snip( .<snip> ),
                        :source( "$lang/$fn" ),
                        :$src-caption,
                        :$targ-in-fn,
                    )
                }
            }
        }
        # generate the composite files
        for %things.kv -> $kind, %defns {
            for %defns.kv -> $dn, @dn-data {
                my $mapped-name = "$prefix/" ~ nqp::sha1( "$lang/$kind/$dn" );
                my $fn-new = "{ $kind.Str.lc }/$dn";
                my $esc-dn = $dn.subst(/ <-[ a .. z A .. Z 0 .. 9 _ \- \. ~ ]> /,
                    *.encode>>.fmt('%%%02X').join, :g);
                # special case '.','..','\'
                $esc-dn ~= '_(as_name)' if $dn eq any( < . .. >);
                $esc-dn = 'backslash character' if $dn eq '\\';
                my $url = "$lang/{ $kind.Str.lc }/$esc-dn";
                %url-maps{ $url } = $mapped-name;
                %url-maps{ $fn-new.subst(/\"/,'\"',:g) } = $mapped-name;
                %aliases{ $fn-new.subst(/\"/,'\"',:g) } = $url;
                #| legacy name for old URLs, will not have lang prefix
                my $fn-name-old = good-name($dn);
                unless $fn-name-old eq $dn {
                    $fn-name-old = '/' ~ $kind.Str.lc ~ '/' ~ $fn-name-old.subst(/\"/,'\"',:g);
                    %url-maps{ $fn-name-old } = $mapped-name;
                    %aliases{ $fn-name-old } = $url;
                }
                #| subtitle variable is attached to file data for search function
                #| but shortened for actual file SUBTITLE
                my @sources;
                my $comp-ast = qq:to/QAST/.AST;
                    =begin rakudoc :kind<{ $kind }>
                    =TITLE The $dn $kind
                    =SUBTITLE Combined from primary sources listed below.
                    =end rakudoc
                    QAST
                my $ast-paras := $comp-ast.rakudoc.head;
                for @dn-data {
                    $ast-paras.add-paragraph( RakuAST::Doc::Block.from-paragraphs(
                        :type<head>,
                        :1level,
                        :paragraphs( 'In ' ~ .<src-caption> , ),
                        :config(%( id => RakuAST::StrLiteral.new($url),  ))
                    ));
                    @sources.push: .<source>;
                    $ast-paras.add-paragraph( RakuAST::Doc::Paragraph.new(
                        'See primary docmentation ',
                        RakuAST::Doc::Markup.new(
                          :letter<L>,
                          :atoms('in context'),
                          :meta( .<source> ~ '#' ~ .<targ-in-fn>  )
                        ),
                        ' for ',
                        RakuAST::Doc::Markup.new(:letter<B>, :atoms( .<subkind> ~ " $dn")),
                        '.'
                    ));
                    $ast-paras.add-paragraph( .<snip> );
                }
                my $rv = $rdp.render($comp-ast,:source-data( %(:name('&#x1F916;'), :path($url), :$lang, :modified(now) )));
                CATCH {
                     default {
                         $*ERR.say: .message;
                         for .backtrace.reverse {
                             next if .file.starts-with('SETTING::');
                             next unless .subname;
                             $*ERR.say: "  in block {.subname} at {.file} line {.line}";
                             last if .file.starts-with('NQP::')
                         }
                     }
                }
                "$to/$mapped-name\.html".IO.spurt: $rv;
                $rdp.file-data{$lang}{$fn-new}{ .key } = .value for %(
                    title => 'The <b>' ~ $dn.trans(qw｢ &lt; &gt; &amp; &quot; ｣ => qw｢ <    >    &   " ｣) ~ "</b> $kind",
                    subtitle => 'From: ' ~ @sources.join(', ') ~ '.',
                    config => %( :$kind, :!index ),
                    :modified(now),
                    :composite,
                ).pairs;
            }
        }
        # store the mapped URLs
        "$prefix/pretty-urls".IO.spurt: %url-maps.pairs.map({ .key.raku ~ ' ' ~ .value.raku }).join("\n")
    }
}