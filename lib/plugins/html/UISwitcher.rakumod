use v6.d;
use RakuDoc::Templates;
use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::UISwitcher;
has %.config =
    :name-space<uiswitcher>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :js([self.js-text,3],),
;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-templates( $.templates, :source<UISwitcher plugin> );
    $rdp.add-data( %!config<name-space>, %!config );
}
method js-text {

}
method templates {

}