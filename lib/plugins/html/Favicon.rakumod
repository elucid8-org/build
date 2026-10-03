use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::Favicon;

has %.config =
        :name-space<Favicon>,
        :version<0.1.0>,
        :license<Artistic-2.0>,
        :credit<finanalyst>,
        :authors<finanalyst>,
        :move-favicon(-> %config {
            self.move-favicon(%config)
        }),
        ;
method enable(RakuDoc::Processor:D $rdp) {
    $rdp.add-data(%!config<name-space>, %!config);
    $rdp.add-template(self.template, :source<Favicon plugin>);
}
method template {
    favicon => -> %prm, $tmpl {
        q[<link rel="icon" href="/assets/favicon.ico">]
    }
}
method move-favicon(%config) {
    # move icon to assets/ directory
    # assets is not localised, but publication/ is localised
    if %config<favicon-file> -> $_ {
        .IO.copy:  (%config<publication> ~ '/assets/favicon.ico').IO
    }
    else {
        %?RESOURCES{"favicon.ico"}.copy: (%config<publication> ~ '/assets/favicon.ico').IO
    }
}
