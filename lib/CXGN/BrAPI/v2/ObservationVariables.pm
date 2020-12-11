package CXGN::BrAPI::v2::ObservationVariables;

use Moose;
use Data::Dumper;
use JSON;
use CXGN::Trait;
use CXGN::BrAPI::Pagination;
use CXGN::BrAPI::JSONResponse;
use SGN::Model::Cvterm;

extends 'CXGN::BrAPI::v2::Common';

sub observation_levels {
    my $self = shift;
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;

    my @data_window;
    push @data_window, ({
            levelName => 'replicate',
            levelOrder => 0 }, 
        {
            levelName => 'block',
            levelOrder => 1 },
        {
            levelName => 'plot',
            levelOrder => 2 },
        {
            levelName => 'subplot',
            levelOrder => 3 },
        {
            levelName => 'plant',
            levelOrder => 4 },
        {
            levelName => 'tissue_sample',
            levelOrder => 5 
         });

    my $total_count = 6;

    my @data_files;
    my %result = (data=>\@data_window);
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$total_count,$page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Observation Levels result constructed');   
}

sub search {
    my $self = shift;
    my $inputs = shift;
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;
    my $supported_crop = $inputs->{supportedCrop};
    my @classes = $inputs->{traitClasses} ? @{$inputs->{traitClasses}} : ();
    my @cvterm_names = $inputs->{observationVariableNames} ? @{$inputs->{observationVariableNames}} : ();
    my @datatypes = $inputs->{datatypes} ? @{$inputs->{datatypes}} : ();
    my @db_ids = $inputs->{ontologyDbIds} ? @{$inputs->{ontologyDbIds}} : ();
    my @dbxref_ids = $inputs->{externalReferenceIDs} ? @{$inputs->{externalReferenceIDs}} : ();
    my @dbxref_terms = $inputs->{externalReferenceSources} ? @{$inputs->{externalReferenceSources}} : ();
    my @method_ids = $inputs->{methodDbIds} ? @{$inputs->{methodDbIds}} : ();
    my @scale_ids = $inputs->{scaleDbIds} ? @{$inputs->{scaleDbIds}} : ();
    my @study_ids = $inputs->{studyDbId} ? @{$inputs->{studyDbIds}} : ();
    my @trait_dbids = $inputs->{traitDbIds} ? @{$inputs->{traitDbIds}} : ();
    my @trait_ids = $inputs->{observationVariableDbIds} ? @{$inputs->{observationVariableDbIds}} : ();

    if (scalar(@classes)>0 || scalar(@method_ids)>0 || scalar(@scale_ids)>0 || scalar(@study_ids)>0){
        push @$status, { 'error' => 'The following parameters are not implemented: scaleDbId, studyDbId, traitClasses, methodDbId' };
    }
   
    my $join = '';
    my @and_wheres;
    if (scalar(@trait_ids)>0){
        my $trait_ids_sql = join ',', @trait_ids;
        push @and_wheres, "cvterm.cvterm_id IN ($trait_ids_sql)";
    }
    if (scalar(@trait_dbids)>0){
        my $trait_ids_sql = join ',', @trait_dbids;
        push @and_wheres, "cvterm.cvterm_id IN ($trait_ids_sql)";
    }
    if (scalar(@db_ids)>0){
        foreach (@db_ids){
            push @and_wheres, "db.db_id = '$_'";
        }
    }
    if (scalar(@dbxref_ids)>0){
        my @db_names;
        my @dbxref_accessions;
        foreach (@dbxref_ids){
            my ($db_name, $accession) = split ':', $_;
            push @db_names, $db_name;
            push @dbxref_accessions, $accession;
        }
        foreach (@db_names){
            push @and_wheres, "db.name = '$_'";
        }
        foreach (@dbxref_accessions){
            push @and_wheres, "dbxref.accession = '$_'";
        }
    }
    if (scalar(@dbxref_terms)>0){
        my @db_names;
        foreach (@dbxref_terms){
            my ($db_name, $accession) = split ':', $_;
            push @db_names, $db_name;
        }
        foreach (@db_names){
            push @and_wheres, "db.name = '$_'";
        }
    }
    if (scalar(@cvterm_names)>0){
        foreach (@cvterm_names){
            push @and_wheres, "cvterm.name = '$_'";
        }
    }
    if (scalar(@datatypes)>0){
        $join = 'JOIN cvtermprop on (cvterm.cvterm_id=cvtermprop.cvterm_id)';
        foreach (@datatypes){
            push @and_wheres, "cvtermprop.value = '$_'";
        }
    }

    push @and_wheres, "reltype.name='VARIABLE_OF'";

    my $and_where_clause = join ' AND ', @and_wheres;

    my @data;
    my $limit = $page_size;
    my $offset = $page*$page_size;
    my $total_count = 0;
    my $q = "SELECT cvterm.cvterm_id, cvterm.name, cvterm.definition, db.name, db.db_id, db.url, dbxref.accession, array_agg(cvtermsynonym.synonym), cvterm.is_obsolete, count(cvterm.cvterm_id) OVER() AS full_count FROM cvterm ". 
        "JOIN dbxref USING(dbxref_id) ".
        "JOIN db using(db_id) ".
        "JOIN cvtermsynonym using(cvterm_id) ". # left join if want to include variables without synonyms
        "inner JOIN cvterm_relationship as rel on (rel.subject_id=cvterm.cvterm_id) ".
        "JOIN cvterm as reltype on (rel.type_id=reltype.cvterm_id) $join ".
        "WHERE $and_where_clause ".
        "GROUP BY cvterm.cvterm_id, db.name, db.db_id, dbxref.accession ". 
        "ORDER BY cvterm.name ASC LIMIT $limit OFFSET $offset;";

    my $sth = $self->bcs_schema->storage->dbh->prepare($q);
    $sth->execute();
    while (my ($cvterm_id, $cvterm_name, $cvterm_definition, $db_name, $db_id, $db_url, $accession, $synonym, $obsolete, $count) = $sth->fetchrow_array()) {
        $total_count = $count;
        foreach (@$synonym){
            $_ =~ s/ EXACT \[\]//;
            $_ =~ s/\"//g;
        }

        my $trait = CXGN::Trait->new({bcs_schema=>$self->bcs_schema, cvterm_id=>$cvterm_id});
        my $categories = $trait->categories;
        my @brapi_categories = split '/', $categories;
        push @data, {
            additionalInfo => {},
            commonCropName => $supported_crop,
            contextOfUse => undef,
            defaultValue => $trait->default_value,
            documentationURL => $trait->uri,
            externalReferences => $db_name.":".$accession,
            growthStage => undef,
            institution  => undef,
            language => 'eng',
            method => {},
                # additionalInfo
                # bibliographicalReference
                # description
                # externalReferences
                # formula
                # methodClass
                # methodDbId
                # methodName
                # ontologyReference => {
                #         documentationLinks
                #         ontologyDbId
                #         ontologyName
                #         version
                #     }
            observationVariableDbId => qq|$cvterm_id|,
            observationVariableName => $cvterm_name."|".$db_name.":".$accession,
            ontologyReference => {
                documentationLinks => $db_url,
                ontologyDbId => qq|$db_id|,
                ontologyName => $db_name,
                version => undef,
            },
            scale => {
                additionalInfo => {},
                datatype => $trait->format,
                decimalPlaces => undef,
                externalReferences => '',
                ontologyReference => {},
                #         documentationLinks
                #         ontologyDbId
                #         ontologyName
                #         version
                scaleDbId => undef,
                scaleName => undef,
                validValues => {
                    min =>$trait->minimum ? $trait->minimum : undef,
                    max =>$trait->maximum ? $trait->maximum : undef,
                    categories => \@brapi_categories,
                },

            },
            scientist => undef,
            status => $obsolete = 0 ? "Obsolete" : "Active",
            submissionTimestamp => undef,
            synonyms => $synonym,
            trait => {
                additionalInfo => {},
                alternativeAbbreviations => undef,
                attribute => $cvterm_name,
                entity => undef,
                externalReferences => $db_name.":".$accession,
                mainAbbreviation => undef,
                ontologyReference => {
                        documentationLinks => $trait->uri ? $trait->uri : undef,
                        ontologyDbId => $trait->db_id ? $trait->db_id : undef,
                        ontologyName => $trait->db ? $trait->db : undef,
                        version => undef,
                    },
                status => $obsolete = 0 ? "Obsolete" : "Active",
                synonyms => $synonym,
                traitClass => undef,
                traitDescription => $cvterm_definition,
                traitDbId => qq|$cvterm_id|,
                traitName => $cvterm_name,
            },
        };
    }

    my %result = (data=>\@data);
    my @data_files;
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Observationvariable search result constructed');
}

sub detail {
    my $self = shift;
    my $trait_id = shift;
    my $c = shift;
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;
    my $supported_crop = $c->config->{'supportedCrop'};
   
    my $join = '';
    my $and_where;
    if ($trait_id){
        $and_where = "cvterm.cvterm_id IN ($trait_id)";
    }

    my %result;
    my $limit = $page_size;
    my $offset = $page*$page_size;
    my $total_count = 0;
    my $q = "SELECT cvterm.cvterm_id, cvterm.name, cvterm.definition, db.name, db.db_id, db.url, dbxref.dbxref_id, dbxref.accession, array_agg(cvtermsynonym.synonym), cvterm.is_obsolete, count(cvterm.cvterm_id) OVER() AS full_count FROM cvterm ".
        "JOIN dbxref USING(dbxref_id) ".
        "JOIN db using(db_id) ".
        "JOIN cvtermsynonym using(cvterm_id) ". # left join if want to include variables without synonyms
        "JOIN cvterm_relationship as rel on (rel.subject_id=cvterm.cvterm_id) ".
        "JOIN cvterm as reltype on (rel.type_id=reltype.cvterm_id) $join ".
        "WHERE $and_where " .
        "GROUP BY cvterm.cvterm_id, db.name, db.db_id, dbxref.dbxref_id, dbxref.accession ".
        "ORDER BY cvterm.name ASC LIMIT $limit OFFSET $offset; "  ;

    my $sth = $self->bcs_schema->storage->dbh->prepare($q);
    $sth->execute();
    while (my ($cvterm_id, $cvterm_name, $cvterm_definition, $db_name, $db_id, $db_url, $dbxref_id, $accession, $synonym, $obsolete, $count) = $sth->fetchrow_array()) {
        $total_count = $count;
        foreach (@$synonym){
            $_ =~ s/ EXACT \[\]//;
            $_ =~ s/\"//g;
        }
        my $trait = CXGN::Trait->new({bcs_schema=>$self->bcs_schema, cvterm_id=>$cvterm_id});
        my $references = CXGN::BrAPI::v2::ExternalReferences->new({
            bcs_schema => $self->bcs_schema,
            dbxref_id => $dbxref_id
        });
        my $external_references = $references->references_db();
        my $categories = $trait->categories;
        my @brapi_categories = split '/', $categories;
        %result = (
            additionalInfo => undef,
            commonCropName => $supported_crop,
            contextOfUse => undef,
            defaultValue => $trait->default_value,
            documentationURL => $trait->uri,
            externalReferences => $external_references, #$db_name.":".$accession,
            growthStage => undef,
            institution  => undef,
            language => 'eng',
            method => {
                # additionalInfo
                # bibliographicalReference
                # description
                # externalReferences
                # formula
                # methodClass
                # methodDbId
                # methodName
                # ontologyReference => {
                #         documentationLinks
                #         ontologyDbId
                #         ontologyName
                #         version
                #     }
                },
            observationVariableDbId => qq|$cvterm_id|,
            observationVariableName => $cvterm_name."|".$db_name.":".$accession,
            ontologyReference => {
                documentationLinks => $db_url,
                ontologyDbId => qq|$db_id|,
                ontologyName => $db_name,
                version => undef,
            },
            scale => {
                datatype => $trait->format,
                decimalPlaces => undef,
                externalReferences => '',
                ontologyReference => {
                #         documentationLinks
                #         ontologyDbId
                #         ontologyName
                #         version
                },
                scaleDbId => undef,
                scaleName => undef,
                validValues => {
                    min =>$trait->minimum ? $trait->minimum : undef,
                    max =>$trait->maximum ? $trait->maximum : undef,
                    categories => \@brapi_categories,
                },

            },
            scientist => undef,
            status => $obsolete = 0 ? "Obsolete" : "Active",
            submissionTimestamp => undef,
            synonyms => $synonym,
            trait => {
                alternativeAbbreviations => undef,
                attribute => $cvterm_name,
                entity => undef,
                externalReferences => $db_name.":".$accession,
                mainAbbreviation => undef,
                ontologyReference => {
                        documentationLinks => $trait->uri ? $trait->uri : undef,
                        ontologyDbId => $trait->db_id ? $trait->db_id : undef,
                        ontologyName => $trait->db ? $trait->db : undef,
                        version => undef,
                    },
                status => $obsolete = 0 ? "Obsolete" : "Active",
                synonyms => $synonym,
                traitClass => undef,
                traitDescription => $cvterm_definition,
                traitDbId => qq|$cvterm_id|,
                traitName => $cvterm_name,
            },
        );
    }

    # my %result = (data=>\@data);
    my @data_files;
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($total_count,$page_size,$page);
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Observationvariable search result constructed');
}

# TODO: handle create and update, just create for now
sub store {

    my $self = shift;
    my $data = shift;
    my $user_id = shift;
    my $c = shift;

    my $page_size = $self->page_size;
    my $page = $self->page;
    my $schema = $self->bcs_schema();

    my @variable_ids;

    # nothing for now, eventually edit
    my $cvterm_id = undef;
    my $supported_crop = $c->config->{'supportedCrop'};
    my %result;

    #print Dumper($data);
    foreach my $params (@{$data}) {
        my $cvterm_id = $params->{observationVariableDbId} || undef;
        my $name = $params->{observationVariableName};
        my $ontology_id = $params->{ontologyReference}{ontologyDbId};
        my $description = $params->{trait}{traitDescription};
        my $synonyms = $params->{trait}{synonyms};
        my $references = $params->{externalReferences};
        my $trait = CXGN::Trait->new({ bcs_schema => $self->bcs_schema,
            cvterm_id                             => $cvterm_id,
            name                                  => $name,
            ontology_id                           => $ontology_id,
            definition                            => $description,
            synonyms                              => $synonyms,
            external_references                   => $references
        });
        my $variable = $trait->store();

        if ($variable->{'error'}) {
            # TODO: status codes
            return CXGN::BrAPI::JSONResponse->return_error($self->status, $variable->{'error'});
        } else {
            $variable = $variable->{variable};
            push @variable_ids, $variable;
            #print "New variable is ".Dumper($variable)."\n";
        }

        %result = (
            additionalInfo => undef,
            commonCropName => $supported_crop,
            contextOfUse => undef,
            defaultValue => $variable->default_value,
            documentationURL => $variable->uri,
            # externalReferences => $db_name.":".$accession,
            growthStage => undef,
            institution  => undef,
            language => 'eng',
            method => {
                # additionalInfo
                # bibliographicalReference
                # description
                # externalReferences
                # formula
                # methodClass
                # methodDbId
                # methodName
                # ontologyReference => {
                #         documentationLinks
                #         ontologyDbId
                #         ontologyName
                #         version
                #     }
            },
            observationVariableDbId => $variable->cvterm_id,
            observationVariableName => $variable->display_name,
            ontologyReference => {
                documentationLinks => $variable->uri ? $variable->uri : undef,
                ontologyDbId => $variable->db_id ? $variable->db_id : undef,
                ontologyName => $variable->db ? $variable->db : undef,
                version => undef,
            },
            scale => {
                datatype => $variable->format,
                decimalPlaces => undef,
            #     externalReferences => '',
                ontologyReference => {
                    documentationLinks => $variable->uri ? $variable->uri : undef,
                    ontologyDbId => $variable->db_id ? $variable->db_id : undef,
                    ontologyName => $variable->db ? $variable->db : undef,
                    version => undef,
                },
                scaleDbId => undef,
                scaleName => undef,
                validValues => {
                    min =>$variable->minimum ? $variable->minimum : undef,
                    max =>$variable->maximum ? $variable->maximum : undef,
                    #categories => \@brapi_categories,
                },
            #
            },
            scientist => undef,
            # status => $obsolete = 0 ? "Obsolete" : "Active",
            submissionTimestamp => undef,
            # synonyms => $synonym,
            trait => {
                alternativeAbbreviations => undef,
            #     attribute => $cvterm_name,
                entity => undef,
            #     externalReferences => $db_name.":".$accession,
                mainAbbreviation => undef,
                ontologyReference => {
                    documentationLinks => $variable->uri ? $variable->uri : undef,
                    ontologyDbId => $variable->db_id ? $variable->db_id : undef,
                    ontologyName => $variable->db ? $variable->db : undef,
                    version => undef,
                },
            #     status => $obsolete = 0 ? "Obsolete" : "Active",
            #     synonyms => $synonym,
                traitClass => undef,
            #     traitDescription => $cvterm_definition,
                traitDbId => $variable->cvterm_id,
            #     traitName => $cvterm_name,
            },
        );
    }

    my $count = scalar @variable_ids;
    my $pagination = CXGN::BrAPI::Pagination->pagination_response($count,$page_size,$page);
    return CXGN::BrAPI::JSONResponse->return_success( \%result, $pagination, undef, $self->status(), $count . " Variables were saved.");
}

sub observation_variable_ontologies {
    my $self = shift;
    my $inputs = shift;
    my $name_spaces = $inputs->{name_spaces};
    my $ontology_id = $inputs->{ontologyDbId};
    my $cvprop_types = $inputs->{cvprop_type_names} || [];
    my $page_size = $self->page_size;
    my $page = $self->page;
    my $status = $self->status;
    my @available;

    my @composable_cv_prop_types;
    foreach (@$cvprop_types) {
        my $composable_cv_type_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->bcs_schema, $_, 'composable_cvtypes')->cvterm_id();
        push @composable_cv_prop_types, $composable_cv_type_cvterm_id;
    }
    my $composable_cv_prop_sql  = "";
    if (scalar(@composable_cv_prop_types)>0) {
        $composable_cv_prop_sql = join ("," , @composable_cv_prop_types);
        $composable_cv_prop_sql = " AND cvprop.type_id IN ($composable_cv_prop_sql)";
    }

    #Using code pattern from SGN::Controller::AJAX::Onto->roots_GET
    my $q = "SELECT cvterm.cvterm_id, cvterm.name, cvterm.definition, db.name, db.db_id, dbxref.accession, dbxref.version, dbxref.description, cv.cv_id, cv.name, cv.definition FROM cvterm JOIN dbxref USING(dbxref_id) JOIN db USING(db_id) JOIN cv USING(cv_id) JOIN cvprop USING(cv_id) LEFT JOIN cvterm_relationship ON (cvterm.cvterm_id=cvterm_relationship.subject_id) WHERE cvterm_relationship.subject_id IS NULL AND is_obsolete= 0 AND is_relationshiptype = 0 and db.name=? $composable_cv_prop_sql;";
    my $sth = $self->bcs_schema->storage->dbh->prepare($q);
    foreach (@$name_spaces){
        $sth->execute($_);
        while (my ($cvterm_id, $cvterm_name, $cvterm_definition, $db_name, $db_id, $dbxref_accession, $dbxref_version, $dbxref_description, $cv_id, $cv_name, $cv_definition) = $sth->fetchrow_array()) {
            if ( $ontology_id &&  $ontology_id ne $db_id) { next; }
            my $info;
            if($dbxref_description){
                $info = decode_json($dbxref_description);
            }
            push @available, {
                additionalInfo=>{},
                ontologyDbId=>qq|$db_id|,
                ontologyName=>$db_name,
                description=>$cvterm_name,
                authors=>$info->{authors} ? $info->{authors} : '',
                version=>$dbxref_version,
                copyright=>$info->{copyright} ? $info->{copyright} : '',
                licence=>$info->{licence} ? $info->{licence} : '',
                documentationURL=>$dbxref_accession,
            };
        }
    }

    my ($data_window, $pagination) = CXGN::BrAPI::Pagination->paginate_array(\@available,$page_size,$page);
    my %result = (data=>$data_window);
    my @data_files;
    return CXGN::BrAPI::JSONResponse->return_success(\%result, $pagination, \@data_files, $status, 'Ontologies result constructed');
}

1;
