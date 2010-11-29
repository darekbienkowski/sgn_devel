use strict;
use warnings;

use CXGN::DB::Connection;
use CXGN::Genomic::Search::Clone;
use CXGN::Page::FormattingHelpers qw/page_title_html modesel/;
use CXGN::Page;
use CXGN::People;
use CXGN::Search::CannedForms;

our $page = CXGN::Page->new( "SGN Direct Search page", "Koni");

my @tabs = (
	    ['?search=loci','Genes'],
	    ['?search=phenotypes','Phenotypes'],
	    ['?search=qtl','QTLs'],
    	    ['?search=trait', 'Traits'],
    	    ['?search=unigene','Unigenes'],
	    ['?search=family', 'Unigene Families' ],
	    ['?search=markers','Markers'],
	    ['?search=bacs','Genomic Clones'],
	    ['?search=est_library','ESTs'],
	    ['?search=images','Images'],	
	    ['?search=directory','People'],
            ['?search=template_experiment_platform', 'Expression']
	   );
my @tabfuncs = (
		\&gene_tab,
		\&phenotype_tab,
		\&qtl_tab,
                \&trait_tab,
		\&unigene_tab,
		\&family_tab,
		\&marker_tab,
		\&bac_tab,
		\&est_library_submenu,
                \&images_tab,	
		\&directory_tab,
                \&template_experiment_platform_submenu,
    );

#get the search type
my ($search) = $page -> get_arguments("search");
$search ||= 'unigene'; #default

my $tabsel =
    ($search =~ /loci/i)           ? 0
    : ($search =~ /phenotypes/i)   ? 1  
    : ($search =~ /qtl/i)  ? 2
    : ($search =~ /trait/i)  ? 3
    : ($search =~ /unigene/i)      ? 4
    : ($search =~ /famil((y)|(ies))/i)       ? 5
    : ($search =~ /markers/i)      ? 6
    : ($search =~ /bacs/i)         ? 7
    : ($search =~ /est/i)          ? 8
    : ($search =~ /library/i)      ? 8 
    : ($search =~ /images/i)       ? 9 # New image search
    : ($search =~ /directory/i)    ? 10
    : ($search =~ /template/i)     ? 11 ## There are 3 terms linking to search for expression 
    : ($search =~ /experiment/i)   ? 11
    : ($search =~ /platform/i)     ? 11
    : $page->error_page("Invalid search type '$search'.");

$page->header('Search SGN','Search SGN');

print modesel(\@tabs,$tabsel); #print out the tabs

print qq|<div class="indentedcontent">\n|;
$tabfuncs[$tabsel](); #call the right function for filler
print qq|</div>\n|;

$page->footer();

sub annotation_tab {
    print CXGN::Search::CannedForms::annotation_search_form($page);
}

#display a second level of tabs, allowing the user to choose between EST and library searches
sub est_library_submenu {
	my @tabs = (
		    ['?search=est','ESTs'],
		    ['?search=library','Libraries']);
	my @tabfuncs = (\&est_tab, \&library_tab);
	
	#get the search type
	my ($search) = $page->get_arguments("search");
	$search ||= 'est'; #default
	
	my $tabsel =
	  ($search=~ /est/i)          ? 0
	  : ($search =~ /library/i)   ? 1
	  : $page->error_page("Invalid submenu search type '$search'.");
	
	print modesel(\@tabs, $tabsel); #print out the tabs
	
	print qq|<div>\n|;
	$tabfuncs[$tabsel](); #call the right function for filler
	print qq|</div>\n|;
}

sub est_tab {
    print CXGN::Search::CannedForms::est_search_form($page);
}

sub library_tab {
    print CXGN::Search::CannedForms::library_search_form($page);
}

sub unigene_tab {
    print CXGN::Search::CannedForms::unigene_search_form($page);
}

sub family_tab {
	print CXGN::Search::CannedForms::family_search_form($page);
}

sub marker_tab {

  print <<MARKERTAB;
<h3><b>Marker search</b></h3>
MARKERTAB
  
  my $dbh = CXGN::DB::Connection->new();
  my $mform = CXGN::Search::CannedForms::MarkerSearch->new($dbh);
  print   '<form action="/search/markers/markersearch.pl">'
    . $mform->to_html() .
      '</form>';

}

sub bac_tab {
    print CXGN::Search::CannedForms::clone_search_form($page);
}

sub directory_tab {
    print CXGN::Search::CannedForms::people_search_form($page);
}

sub gene_tab {
    print CXGN::Search::CannedForms::gene_search_form($page);
}
sub phenotype_tab {
    print CXGN::Search::CannedForms::phenotype_search_form($page);
}
sub qtl_tab {
    print CXGN::Search::CannedForms::cvterm_search_form($page);
}
sub trait_tab {
    $page->client_redirect('/trait/search/');
}

sub images_tab {
    print CXGN::Search::CannedForms::image_search_form($page);
}

sub template_experiment_platform_submenu {
        my @tabs = (
                    ['?search=template','Templates'],
                    ['?search=experiment','Experiments'],
                    ['?search=platform', 'Platforms']);
        my @tabfuncs = (\&template_tab, \&experiment_tab, \&platform_tab);
        
        #get the search type
        my ($search) = $page->get_arguments("search");
        $search ||= 'template'; #default
        
        my $tabsel =
          ($search=~ /template/i)          ? 0
          : ($search =~ /experiment/i)   ? 1
          : ($search =~ /platform/i)     ? 2
          : $page->error_page("Invalid submenu search type '$search'.");
        
        print modesel(\@tabs, $tabsel); #print out the tabs
        
        print qq|<div>\n|;
        $tabfuncs[$tabsel](); #call the right function for filler
        print qq|</div>\n|;
}

sub template_tab {
    print CXGN::Search::CannedForms::expr_template_search_form($page);
}

sub experiment_tab {
    print CXGN::Search::CannedForms::expr_experiment_search_form($page);
}

sub platform_tab {
    print CXGN::Search::CannedForms::expr_platform_search_form($page);
}
