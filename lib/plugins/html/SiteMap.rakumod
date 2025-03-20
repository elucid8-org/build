use v6.d;
use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::SiteMap;

has %.config =
    :name-space<SiteMap>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :create-site-map( -> $rdp, %config { self.create-site-map( $rdp, %config ) } ),
    ;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
}
method create-site-map( $rdp, %site-config ) {
    say "Generating site map";
    my %filedata := $rdp.file-data;
    exit note 'Sitemap plugin error. Must set configuration for ｢root-domain｣'
        unless %site-config<plugin-options><SiteMap><root-domain>:exists;
    my $root = %site-config<plugin-options><SiteMap><root-domain>;
    my $sitemap = q:to/START/;
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    START
    my $priority;
    for %filedata.kv -> $lg, %files {
        my $lang =  $lg eq '*' ?? '' !! "$lg/";
        for %files.kv -> $fn, %info {
            given %info<type> {
                when 'glue' { $priority = 0.8 }
                when 'primary' { $priority = 1 }
                when 'composite' { $priority = 0.6 }
                when 'info' { $priority = 0.3 }
                default { $priority = 0.5 }
            }
            my $mod = %info<modified>;
            use MONKEY-SEE-NO-EVAL;
            $mod = EVAL $mod if $mod.isa(Str);
            no MONKEY-SEE-NO-EVAL;
            $mod .= DateTime.yyyy-mm-dd;
            $sitemap ~= qq:to/URL/;
                <url>
                    <loc>$root/$lang$fn.html\</loc>
                    <lastmod>$mod\</lastmod>
                    <priority>$priority\</priority>
                </url>
            URL
        }
    }

    $sitemap ~= q:to/END/;
    </urlset>
    END
    "{ %site-config<publication> }/sitemap.xml".IO.spurt: $sitemap
}
