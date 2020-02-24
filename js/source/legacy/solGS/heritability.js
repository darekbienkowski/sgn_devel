/** 
* heritability coefficients plotting using d3
* Isaak Y Tecle <iyt2@cornell.edu>
*
*/


jQuery(document).ready( function() { 
    var page = document.URL;
   
    if (page.match(/solgs\/traits\/all\//) != null || 
        page.match(/solgs\/models\/combined\/trials\//) != null) {
	
	setTimeout(function() {listGenCorPopulations()}, 5000);
        
    } else {

	var url = window.location.pathname;

	if (url.match(/[solgs\/population|breeders_toolbox\/trial|breeders\/trial]/)) {
	    checkPhenoH2Result();  
	} 
    }
          
});


function checkPhenoH2Result () {
    
    var popDetails = getPopulationDetails();
    var popId      = popDetails.population_id;
   
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
        url: '/phenotype/heritability/check/result/' + popId,
        success: function(response) {
            if (response.result) {
		phenotypicheritability();					
            } else { 
		jQuery("#run_pheno_h2").show();	
            }
	}
    });
    
}


jQuery(document).ready( function() { 

    jQuery("#run_pheno_h2").click(function() {
        phenotypicheritability();
	jQuery("#run_pheno_h2").hide();
    }); 
  
});


jQuery(document).on("click", "#run_genetic_heritability", function() {        
    var popId   = jQuery("#H2_selected_population_id").val();
    var popType = jQuery("#H2_selected_population_type").val();
    
    //jQuery("#heritability_canvas").empty();
   
    jQuery("#heritability_message")
        .css({"padding-left": '0px'})
        .html("Running genetic heritability analysis...");
    
    formatGenCorInputData(popId, popType);
         
});


function listGenCorPopulations ()  {
    var modelData = solGS.sIndex.getTrainingPopulationData();
   
    var trainingPopIdName = JSON.stringify(modelData);
   
    var  popsList =  '<dl id="H2_selected_population" class="H2_dropdown">'
        + '<dt> <a href="#"><span>Choose a population</span></a></dt>'
        + '<dd>'
        + '<ul>'
        + '<li>'
        + '<a href="#">' + modelData.name + '<span class=value>' + trainingPopIdName + '</span></a>'
        + '</li>';  
 
    popsList += '</ul></dd></dl>'; 
   
    jQuery("#H2_select_a_population_div").empty().append(popsList).show();
     
    var dbSelPopsList;
    if (modelData.id.match(/list/) == null) {
        dbSelPopsList = solGS.sIndex.addSelectionPopulations();
    }

    if (dbSelPopsList) {
            jQuery("#H2_select_a_population_div ul").append(dbSelPopsList); 
    }
      
    var listTypeSelPops = jQuery("#list_type_selection_pops_table").length;
   
    if (listTypeSelPops) {
        var selPopsList = solGS.sIndex.getListTypeSelPopulations();

        if (selPopsList) {
            jQuery("#H2_select_a_population_div ul").append(selPopsList);  
        }
    }

    jQuery(".H2_dropdown dt a").click(function() {
        jQuery(".H2_dropdown dd ul").toggle();
    });
                 
    jQuery(".H2_dropdown dd ul li a").click(function() {
      
        var text = jQuery(this).html();
           
        jQuery(".H2_dropdown dt a span").html(text);
        jQuery(".H2_dropdown dd ul").hide();
                
        var idPopName = jQuery("#H2_selected_population").find("dt a span.value").html();
        idPopName     = JSON.parse(idPopName);
        modelId       = jQuery("#model_id").val();
                   
        var selectedPopId   = idPopName.id;
        var selectedPopName = idPopName.name;
        var selectedPopType = idPopName.pop_type; 
       
        jQuery("#H2_selected_population_name").val(selectedPopName);
        jQuery("#H2_selected_population_id").val(selectedPopId);
        jQuery("#H2_selected_population_type").val(selectedPopType);
                                
    });
                       
    jQuery(".H2_dropdown").bind('click', function(e) {
        var clicked = jQuery(e.target);
               
        if (! clicked.parents().hasClass("H2_dropdown"))
            jQuery(".H2_dropdown dd ul").hide();

        e.preventDefault();

    });           
}


function formatGenCorInputData (popId, type, indexFile) {
    var modelDetail = getPopulationDetails();

    
    var traitsIds = jQuery('#training_traits_ids').val();
    if(traitsIds) {
	traitsIds = traitsIds.split(',');
    }

    var modelId  = modelDetail.population_id;
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
        data: {'model_id': modelId,
	       'h2_population_id': popId,
	       'traits_ids': traitsIds,
	       'type' : type,
	       'index_file': indexFile},
        url: '/heritability/genetic/data/',
        success: function(response) {

            if (response.status) {
		
                gebvsFile = response.gebvs_file;
		indexFile = response.index_file;
		
                var divPlace;
                if (indexFile) {
                    divPlace = '#si_heritability_canvas';
                }

                var args = {
                    'model_id': modelDetail.population_id, 
                    'h2_population_id': popId, 
                    'type': type,
		    'traits_ids': traitsIds,
                    'gebvs_file': gebvsFile,
		    'index_file': indexFile,
                    'div_place' : divPlace,
                };
		
                runGenheritabilityAnalysis(args);

            } else {
                jQuery(divPlace +" #heritability_message")
                    .css({"padding-left": '0px'})
                    .html("This population has no valid traits to H2late.");
		
            }
        },
        error: function(response) {
            jQuery(divPlace +"#heritability_message")
                .css({"padding-left": '0px'})
                .html("Error occured preparing the additive genetic data for heritability analysis.");
	         
            jQuery.unblockUI();
        }         
    });
}


function getPopulationDetails () {

    var populationId = jQuery("#population_id").val();
    var populationName = jQuery("#population_name").val();
   
    if (populationId == 'undefined') {       
        populationId = jQuery("#model_id").val();
        populationName = jQuery("#model_name").val();
    }

    return {'population_id' : populationId, 
            'population_name' : populationName
           };        
}


function phenotypicheritability () {
 
    var population = getPopulationDetails();
    
    jQuery("#heritability_message").html("Running heritability... please wait...");
         
    jQuery.ajax({
            type: 'POST',
            dataType: 'json',
            data: {'population_id': population.population_id },
            url: '/heritability/phenotype/data/',
            success: function(response) {
	
                if (response.result) {
                    runPhenoheritabilityAnalysis();
                } else {
                    jQuery("#heritability_message")
                        .css({"padding-left": '0px'})
                        .html("This population has no phenotype data.");

		    jQuery("#run_pheno_h2").show();
                }
            },
            error: function(response) {
                jQuery("#heritability_message")
                    .css({"padding-left": '0px'})
                    .html("Error occured preparing the phenotype data for heritability analysis.");

		jQuery("#run_pheno_h2").show();
            }
    });     
}


function runPhenoheritabilityAnalysis () {
    var population = getPopulationDetails();
    var popId     = population.population_id;
   
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
        data: {'population_id': popId },
        url: '/phenotypic/heritability/analysis/output',
        success: function(response) {
            if (response.status== 'success') {
                plotheritability(response.data);
		
		var h2Download = "<a href=\"/download/phenotypic/heritability/population/" 
		                    + popId + "\">Download heritability coefficients</a>";

		jQuery("#heritability_canvas").append("<br />[ " + h2Download + " ]").show();
	
		if(document.URL.match('/breeders/trial/')) {
		    displayTraitAcronyms(response.acronyms);
		}
		
                jQuery("#heritability_message").empty();
		jQuery("#run_pheno_h2").hide();
            } else {
                jQuery("#heritability_message")
                    .css({"padding-left": '0px'})
                    .html("There is no heritability output for this dataset."); 
		
		jQuery("#run_pheno_h2").show();
            }
        },
        error: function(response) {                          
            jQuery("#heritability_message")
                .css({"padding-left": '0px'})
                .html("Error occured running the heritability analysis.");
	    	
	    jQuery("#run_pheno_h2").show();
        }                
    });
}


function runGenheritabilityAnalysis (args) {
   
    jQuery.ajax({
        type: 'POST',
        dataType: 'json',
        data: args,
        url: '/genetic/heritability/analysis/output',
        success: function(response) {
            if (response.status == 'success') {
                
                divPlace = args.div_place;
               
                if (divPlace === '#si_heritability_canvas') {
		    jQuery("#si_heritability_message").empty();
                    jQuery("#si_heritability_section").show();                 
                }
             
                plotheritability(response.data, divPlace);
                jQuery("#heritability_message").empty();
               
                
                if (divPlace === '#si_heritability_canvas') {
  
                    var popName   = jQuery("#selected_population_name").val();                   
                    var corLegDiv = "<div id=\"si_heritability_" 
                        + popName.replace(/\s/g, "") 
                        + "\"></div>";  
                
                    var legendValues = solGS.sIndex.legendParams();                 
                    var corLegDivVal = jQuery(corLegDiv).html(legendValues.legend);
            
                    jQuery("#si_heritability_canvas").append(corLegDivVal).show();
  
                } else {
                    
                    var popName = jQuery("#H2_selected_population_name").val(); 
                    var corLegDiv  = "<div id=\"H2_heritability_" 
                        + popName.replace(/\s/g, "") 
                        + "\"></div>";
                    
                    var corLegDivVal = jQuery(corLegDiv).html(popName);            
                    jQuery("#heritability_canvas").append(corLegDivVal).show(); 
                }                        
               
            } else {
                jQuery(divPlace + " #heritability_message")
                    .css({"padding-left": '0px'})
                    .html("There is no genetic heritability output for this dataset.");               
            }
            
            jQuery.unblockUI();
        },
        error: function(response) {                          
            jQuery(divPlace +" #heritability_message")
                .css({"padding-left": '0px'})
                .html("Error occured running the genetic heritability analysis.");
             
            jQuery.unblockUI();
        }       
    });
}


function plotheritability (data, divPlace) {

    data = data.replace(/\s/g, '');
    data = data.replace(/\\/g, '');
    data = data.replace(/^\"/, '');
    data = data.replace(/\"$/, '');
    data = data.replace(/\"NA\"/g, 100);
    
    data = JSON.parse(data);
  
    var height = 400;
    var width  = 400;

    var nTraits = data.traits.length;

    if (nTraits < 8) {
        height = height * 0.5;
        width  = width  * 0.5;
    }

    var pad    = {left:70, top:20, right:100, bottom: 70}; 
    var totalH = height + pad.top + pad.bottom;
    var totalW = width + pad.left + pad.right;

    var corXscale = d3.scale.ordinal().domain(d3.range(nTraits)).rangeBands([0, width]);
    var corYscale = d3.scale.ordinal().domain(d3.range(nTraits)).rangeBands([height, 0]);
    var corZscale = d3.scale.linear().domain([-1, 0, 1]).range(["#6A0888","white", "#86B404"]);

    var xAxisScale = d3.scale.ordinal()
        .domain(data.traits)
        .rangeBands([0, width]);

    var yAxisScale = d3.scale.ordinal()
        .domain(data.traits)
        .rangeRoundBands([height, 0]);
  
    if ( divPlace == null) {
        divPlace = '#heritability_canvas'; 
    }

    var svg = d3.select(divPlace)
        .append("svg")
        .attr("height", totalH)
        .attr("width", totalW);

    var xAxis = d3.svg.axis()
        .scale(xAxisScale)
        .orient("bottom");

    var yAxis = d3.svg.axis()
        .scale(yAxisScale)
        .orient("left");
       
    var h2plot = svg.append("g")
        .attr("id", "heritability_plot")
        .attr("transform", "translate(" + pad.left + "," + pad.top + ")");
       
    h2plot.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height +")")
        .call(xAxis)
        .selectAll("text")
        .attr("y", 0)
        .attr("x", 10)
        .attr("dy", ".1em")         
        .attr("transform", "rotate(90)")
        .attr("fill", "#523CB5")
        .style({"text-anchor":"start", "fill": "#523CB5"});
          
    h2plot.append("g")
        .attr("class", "y axis")
        .attr("transform", "translate(0,0)")
        .call(yAxis)
        .selectAll("text")
        .attr("y", 0)
        .attr("x", -10)
        .attr("dy", ".1em")  
        .attr("fill", "#523CB5")
        .style("fill", "#523CB5");
            
    var h2 = [];
    var coefs = [];   
    for (var i=0; i<data.coefficients.length; i++) {
        for (var j=0;  j<data.coefficients[i].length; j++) {
            h2.push({"row":i, "col":j, "value": data.coefficients[i][j]});
            
            if (data.coefficients[i][j] != 100) {
                coefs.push(data.coefficients[i][j]);
            }
        }
    }
                                 
    var cell = h2plot.selectAll("rect")
        .data(h2)  
        .enter().append("rect")
        .attr("class", "cell")
        .attr("x", function (d) { return corXscale(d.col)})
        .attr("y", function (d) { return corYscale(d.row)})
        .attr("width", corXscale.rangeBand())
        .attr("height", corYscale.rangeBand())      
        .attr("fill", function (d) { 
                if (d.value === 100) {return "white";} 
                else {return corZscale(d.value)}
            })
        .attr("stroke", "white")
        .attr("stroke-width", 1)
        .on("mouseover", function (d) {
                if(d.value != 100) {
                    d3.select(this)
                        .attr("stroke", "green")
                    h2plot.append("text")
                        .attr("id", "h2text")
                        .text("[" + data.traits[d.row] 
                              + " vs. " + data.traits[d.col] 
                              + ": " + d3.format(".2f")(d.value) 
                              + "]")
                        .style("fill", function () { 
                            if (d.value > 0) 
                            { return "#86B404"; } 
                            else if (d.value < 0) 
                            { return "#6A0888"; }
                        })  
                        .attr("x", totalW * 0.5)
                        .attr("y", totalH * 0.5)
                        .attr("font-weight", "bold")
                        .attr("dominant-baseline", "middle")
                        .attr("text-anchor", "middle")                       
                }
        })                
        .on("mouseout", function() {
                d3.selectAll("text.h2label").remove()
                d3.selectAll("text#h2text").remove()
                d3.select(this).attr("stroke","white")
            });
            
    h2plot.append("rect")
        .attr("height", height)
        .attr("width", width)
        .attr("fill", "none")
        .attr("stroke", "#523CB5")
        .attr("stroke-width", 1)
        .attr("pointer-events", "none");
   
    var legendValues = []; 
    
    if (d3.min(coefs) > 0 && d3.max(coefs) > 0 ) {
        legendValues = [[0, 0], [1, d3.max(coefs)]];
    } else if (d3.min(coefs) < 0 && d3.max(coefs) < 0 )  {
        legendValues = [[0, d3.min(coefs)], [1, 0]]; 
    } else {
        legendValues = [[0, d3.min(coefs)], [1, 0], [2, d3.max(coefs)]];
    }
 
    var legend = h2plot.append("g")
        .attr("class", "cell")
        .attr("transform", "translate(" + (width + 10) + "," +  (height * 0.25) + ")")
        .attr("height", 100)
        .attr("width", 100);
       
    var recLH = 20;
    var recLW = 20;

    legend = legend.selectAll("rect")
        .data(legendValues)  
        .enter()
        .append("rect")
        .attr("x", function (d) { return 1;})
        .attr("y", function (d) {return 1 + (d[0] * recLH) + (d[0] * 5); })   
        .attr("width", recLH)
        .attr("height", recLW)
        .style("stroke", "black")
        .attr("fill", function (d) { 
            if (d === 100) {return "white"} 
            else {return corZscale(d[1])}
        });
 
    var legendTxt = h2plot.append("g")
        .attr("transform", "translate(" + (width + 40) + "," + ((height * 0.25) + (0.5 * recLW)) + ")")
        .attr("id", "legendtext");

    legendTxt.selectAll("text")
        .data(legendValues)  
        .enter()
        .append("text")              
        .attr("fill", "#523CB5")
        .style("fill", "#523CB5")
        .attr("x", 1)
        .attr("y", function (d) { return 1 + (d[0] * recLH) + (d[0] * 5); })
        .text(function (d) { 
            if (d[1] > 0) { return "Positive"; } 
            else if (d[1] < 0) { return "Negative"; } 
            else if (d[1] === 0) { return "Neutral"; }
        })  
        .attr("dominant-baseline", "middle")
        .attr("text-anchor", "start");

}


function createAcronymsTable (tableId) {
    
    var table = '<table id="' + tableId + '" class="table" style="width:100%;text-align:left">';
    table    += '<thead><tr>';
    table    += '<th>Acronyms</th><th>Trait</th>'; 
    table    += '</tr></thead>';
    table    += '</table>';

    return table;

}


function displayTraitAcronyms (acronyms) {
  
    if (acronyms) {
	var tableId = 'traits_acronyms';	
	var table = createAcronymsTable(tableId);

	jQuery('#heritability_canvas').append(table); 
	   
	jQuery('#' + tableId).dataTable({
		    'searching'    : true,
		    'ordering'     : true,
		    'processing'   : true,
		    'lengthChange' : false,
                    "bInfo"        : false,
                    "paging"       : false,
                    'oLanguage'    : {
		                     "sSearch": "Filter traits: "
		                    },
		    'data'         : acronyms,
	    });
    }
   
}
