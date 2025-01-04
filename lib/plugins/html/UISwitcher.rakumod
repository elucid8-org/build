use v6.d;
use RakuDoc::Templates;
use RakuDoc::Render;
use JSON::Fast;
use PrettyDump;

unit class Elucid8::Plugin::HTML::UISwitcher;
has %.config =
    :name-space<UISwitcher>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :js([[self.js-text,2],]),
    :ui-tokens( %( :UI_Switch<Switch UI>, :LangName<English>)),
    :gather-ui-tokens( -> $rdp, %config { self.create-dictionary( $rdp, %config )}),
;
has Str $!dictionary = '';
has Str $!canonical = 'en';

method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-template( self.templates, :source<UISwitcher plugin>);
}
method create-dictionary( $rdp, %config ) {
    my %d := $rdp.templates.data;
    my %ui-tokens = %d.pairs
        .grep({ .value ~~ Associative })
        .grep({ .value.<ui-tokens> ~~ Associative })
        .map(  *.value.<ui-tokens>.Slip )
        .map({ .key => .value.Str })
        .hash;
    my $dict-fn = %config<L10N> ~ '/' ~ %config<ui-dictionary>;
    my %dict;
    %dict = EVALFILE( $dict-fn ) if $dict-fn.IO ~~ :e & :f;
    my @new-keys = (%ui-tokens (-) %dict{ %config<canonical> }.keys ).keys;
    if @new-keys.elems {
        # Note we are only interested in new keys, not in values on file, which may be edited
        %dict{ %config<canonical> }{ $_ } = %ui-tokens{ $_ } for @new-keys;
        self.store( %dict, $dict-fn);
    }
    # collapse & convert to Str and evaluate closures
    use MONKEY-SEE-NO-EVAL;
    for %dict.kv -> $k, %v {
        %dict{ $k } = %v.pairs.map({
            .key => .value ~~ /^ 'eval' (.+) $/ ??
            EVAL(~$/[0])
            !! .value
        }).hash
    }
    no MONKEY-SEE-NO-EVAL;
    # add _keys field
    $!dictionary = JSON::Fast::to-json( %dict );
    $!canonical = %config<canonical>;
    %d<UISwitcher><js>.push: [ qq:to/SCRIPT/, 1 ];
    /* UISwitcher generated vars */
    var dictionary = $!dictionary;
    var def_canon = '$!canonical';
    SCRIPT
}
method js-text {
    q:to/SCRIPT/;
    /* UISwitcher */
    var UILang;
    var uiselectors;
    var uilang_persisted = function () { return localStorage.getItem('ui_lang');};
    var persist_uilang = function ( uilang ) { localStorage.setItem( 'ui_lang', uilang );};
    document.addEventListener('DOMContentLoaded', function () {
        UILang = uilang_persisted();
        if ( UILang == null ) {
            UILang = def_canon;
        }
        makeUISelector( UILang ); // comes before setUI as it has a label that needs setting
        uiselectors = document.querySelectorAll('.UISelection'); // uiselectors used in setUI
        setUI( UILang );
        uiselectors.forEach( function (elem) {
            elem.addEventListener('click', function( event ) {
                newLang = event.target.getAttribute('data-lang');
                setUI( newLang );
                persist_uilang( newLang );
            })
        })
    });
    function setUI( newLang ) {
        var spans = document.querySelectorAll('.Elucid8-ui');
        spans.forEach( function (elem) {
            token = elem.getAttribute('data-UIToken');
            elem.innerHTML = dictionary[newLang][token];
        });
        uiselectors.forEach( function (rem) {
            if ( rem.getAttribute('data-UIToken') == newLang ) {
                rem.classList.add('is-selected')
            }
            else {
                rem.classList.remove('is-selected');
            }
        })
    };
    function makeUISelector( initial ) {
        elem = document.getElementById('Elucid8_choice');
        label = elem.innerHTML;
        var options = '';
        Object.keys(dictionary).forEach(function(key) {
            isSel = key == def_canon ? ' is-selected' : '';
            options = options +
                '<a class="navbar-item UISelection' + isSel + '"' +
                'data-lang="' + key + '">' + dictionary[key]['langName'] + '</a>';
        });
        elem.innerHTML = '<a class="navbar-link">' + label + '</a>' +
            '<div class="navbar-dropdown">' +
            options +
            '</div>';
    };
    SCRIPT
}
method templates {
    ui-switch-button => -> %prm, $tmpl {
        qq[ <div id="Elucid8_choice" class="%prm<classes>"><span class="Elucid8-ui" data-UIToken="UI_Switch">UI_Switch</span></div> ]
    }
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