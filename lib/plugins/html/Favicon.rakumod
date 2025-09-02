use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::Favicon;

has %.config =
        :name-space<Favicon>,
        :version<0.1.0>,
        :license<Artistic-2.0>,
        :credit<finanalyst>,
        :authors<finanalyst>,
        ;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-template( self.template, :source<Favicon plugin>);
}
method template {
    favicon => -> %prm, $tmpl {
        q[<link rel="icon" href="/assets/favicon.ico">]
    }
}
