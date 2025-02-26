use v6.d;
use RakuDoc::Templates;
use RakuDoc::Render;
use JSON::Fast;
use PrettyDump;

unit class Elucid8::Plugin::HTML::UISwitcher;
has Str $!dictionary = '';
has Str $!canonical = 'en';
has %!dict;
has %.config =
    :name-space<UISwitcher>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :js([[self.js-text,2],]),
    :ui-tokens( %( :UI_Switch<Switch UI>, :LangName<English>)),
    :gather-ui-tokens( -> $rdp, %config { self.create-dictionary( $rdp, %config )}),
    :add-languages( -> %config { self.add-languages( %config ) } ),
    :%!dict,
;

method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-template( self.ui-token-template, :source<UISwitcher plugin>);
}
method add-languages( %config ) {
    %config<language-list> = %!dict.pairs.map({ .key => .value<LangName> }).hash
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
    %!dict = EVALFILE( $dict-fn ) if $dict-fn.IO ~~ :e & :f;
    my @new-keys = (%ui-tokens (-) %!dict{ %config<canonical> }.keys ).keys;
    if @new-keys.elems {
        # Note we are only interested in new keys, not in values on file, which may be edited
        %!dict{ %config<canonical> }{ $_ } = %ui-tokens{ $_ } for @new-keys;
            note 'New UI language tokens detected: ', @new-keys.join(', ');
        $rdp.store( %!dict, %config<L10N> ~ '/ui-dictionary.rakuon' )
    }
    # collapse & convert to Str and evaluate closures
    use MONKEY-SEE-NO-EVAL;
    my %evaled;
    for %!dict.kv -> $k, %v {
        %evaled{ $k } = %v.pairs
            .map({
                .key => .value ~~ /^ 'eval' (.+) $/ ??
                EVAL(~$/[0])
                !! .value
        }).hash
    }
    no MONKEY-SEE-NO-EVAL;
    # add _keys field
    $!dictionary = JSON::Fast::to-json( %evaled );
    $!canonical = %config<canonical>;
    %d<UISwitcher><js>.push: [ qq:to/SCRIPT/, 1 ];
        /* UISwitcher generated vars */
        var dictionary = $!dictionary;
        var def_canon = '$!canonical';
        SCRIPT
}
method ui-token-template {
    ui-switch-contents => -> %prm, $tmpl {
        qq[ <ul id="Elucid8_ui-switch-contents" class="%prm<classes>"></ul> ]
    }
}
method js-text {
    q:to/SCRIPT/;
    /* UISwitcher */
    var UILang;
    var uiselectors;
    var token_spans;
    var uilang_persisted = function () { return localStorage.getItem('ui_lang');};
    var persist_uilang = function ( uilang ) { localStorage.setItem( 'ui_lang', uilang );};
    document.addEventListener('DOMContentLoaded', function () {
        UILang = uilang_persisted();
        if ( UILang == null ) {
            UILang = def_canon;
        }
        makeUISelector( UILang ); // comes before setUI as it has a label that needs setting
        uiselectors = document.querySelectorAll('.UISelection'); // uiselectors used in setUI
        token_spans = document.querySelectorAll('.Elucid8-ui');
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
        token_spans.forEach( function (elem) {
            token = elem.getAttribute('data-UIToken');
            expr = dictionary[newLang][token];
            if ( expr == null ) { expr = dictionary[def_canon][token] };
            elem.innerHTML = expr;
        });
        uiselectors.forEach( function (rem) {
            if ( rem.getAttribute('data-lang') == newLang ) {
                rem.classList.add('is-selected')
            }
            else {
                rem.classList.remove('is-selected');
            }
        })
    };
    function makeUISelector( initial ) {
        elem = document.getElementById('Elucid8_ui-switch-contents');
        var options = '';
        Object.keys(dictionary).forEach(function(key) {
            isSel = key == def_canon ? ' is-selected' : '';
            options = options +
                '<li><a class="navbar-item UISelection' + isSel + '"' +
                'data-lang="' + key + '">' + dictionary[key]['LangName'] + '</a></li>';
        });
        elem.innerHTML = options;
    };
    SCRIPT
}
