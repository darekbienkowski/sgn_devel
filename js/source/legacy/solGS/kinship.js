/**
 * kinship plotting using d3
 * Isaak Y Tecle <iyt2@cornell.edu>
 *
 */


var solGS = solGS || function solGS() {};

solGS.kinship = {

	getKinshipPopDetails: function() {

		var page = location.pathname;
		var popId;
		var kishipUrlArgs;
		var dataStr;
		var protocolId;

		if (page.match(/solgs\/trait\/|solgs\/model\/combined\/trials\//)) {

			popId = jQuery("#training_pop_id").val();
			protocolId = jQuery("#genotyping_protocol_id").val();

		} else if (page.match(/kinship\/analysis/)) {

			kinshipUrlArgs = this.getKinshipArgsFromUrl();
			popId = kinshipUrlArgs.kinship_pop_id;
			dataStr = kinshipUrlArgs.data_structure;
			protocolId = kinshipUrlArgs.genotyping_protocol_id;

		} else if (page.match(/\/selection\/|\/prediction\//)) {

			popId = jQuery("#selection_pop_id").val();
			protocolId = jQuery("#genotyping_protocol_id").val();

		} else if (page.match(/solgs\/traits\/all\/population\/|models\/combined\/trials\//)) {
			popId = jQuery("#training_pop_id").val();
			protocolId = jQuery("#genotyping_protocol_id").val();
		}

		var traitId = jQuery("#trait_id").val();

		return {
			'kinship_pop_id': popId,
			'data_structure': dataStr,
			'genotyping_protocol_id': protocolId,
			'trait_id': traitId,
		};
	},


	getKinshipArgsFromUrl: function() {

		var page = location.pathname;
		if (page == '/kinship/analysis/') {
			page = '/kinship/analysis';
		}
		var urlArgs = page.replace("/kinship/analysis", "")

		if (urlArgs) {
			var args = urlArgs.split(/\/+/);
			var selectId = args[1];
			var protocolId = args[3];

			var dataStr;
			var reg = /\d+/;
			var popId = selectId.match(reg)[0];
			if (selectId.match(/dataset/)) {
				dataStr = 'dataset';
			} else if (selectId.match(/list/)) {
				dataStr = 'list';
			}

			var args = {
				'kinship_pop_id': popId,
				'data_structure': dataStr,
				'genotyping_protocol_id': protocolId,
			};

			return args;
		} else {
			return {};
		}

	},


	loadKinshipPops: function(selectId, selectName, dataStructure) {

		if (selectId.length === 0) {
			alert('The list is empty. Please select a list with content.');
		} else {

			var kinshipTable = jQuery("#kinship_pops_table").doesExist();

			if (!kinshipTable) {
				kinshipTable = this.createTable();
				jQuery("#kinship_pops_selected").append(kinshipTable).show();
			}

			var onClickVal = '<button type="button" id="run_kinship" class="btn btn-success" onclick="solGS.kinship.runKinship(' +
				selectId + ",'" + selectName + "'" + ",'" + dataStructure +
				"'" + ')">Run Kinship</button>';


			var dataType = ['Genotype'];
			var dataTypeOpts = this.createDataTypeSelect(dataType);

			var addRow = '<tr  name="' + dataStructure + '"' + ' id="' + selectId + '">' +
				'<td>' + selectName + '</td>' +
				'<td>' + dataStructure + '</td>' +
				'<td>' + dataTypeOpts + '</td>' +
				'<td id="list_kinship_page_' + selectId + '">' + onClickVal + '</td>' +
				'<tr>';

			var tdId = '#list_kinship_page_' + selectId;
			var addedRow = jQuery(tdId).doesExist();

			if (!addedRow) {
				jQuery("#kinship_pops_table tr:last").after(addRow);
			}
		}

	},

	createTable: function() {
		var kinshipTable = '<table id="kinship_pops_table" class="table table-striped"><tr>' +
			'<th>Population</th>' +
			'<th>Data structure type</th>' +
			'<th>Data type</th>' +
			'<th>Run Kinship</th>' +
			'</tr>' +
			'</td></tr></table>';

		return kinshipTable;
	},


	createDataTypeSelect: function(opts) {
		var dataTypeGroup = '<select class="form-control" id="kinship_data_type_select">';

		for (var i = 0; i < opts.length; i++) {

			dataTypeGroup += '<option value="' +
				opts[i] + '">' +
				opts[i] +
				'</option>';
		}
		dataTypeGroup += '</select>';

		return dataTypeGroup;
	},


	runKinship: function(selectId, selectName, dataStr) {

		var protocolId = jQuery('#genotyping_protocol_id').val();

		var kinshipArgs = {
			'kinship_pop_id': selectId,
			'kinship_pop_name': selectName,
			'data_structure': dataStr,
			'genotyping_protocol_id': protocolId,
			'analysis_type': 'kinship analysis'
		};

		var page;
		if (dataStr) {
			page = '/kinship/analysis/' + dataStr + '_' + selectId + '/gp/' + protocolId;
		} else {
			page = '/kinship/analysis/' + selectId + '/gp/' + protocolId;
		}

		//this.selectAnalysisOption(page, kinshipArgs);
		this.checkCachedKinship(page, kinshipArgs);

	},

	checkCachedKinship: function(page, args) {

		args = JSON.stringify(args);

		jQuery.ajax({
			type: 'POST',
			dataType: 'json',
			data: {
				'page': page,
				'arguments': args
			},
			url: '/solgs/check/cached/result/',
			success: function(response) {
				args = JSON.parse(args);
				if (response.cached) {
					// solGS.submitJob.goToPage(page, args);
					solGS.kinship.getKinshipResult(args);
				} else {
					solGS.kinship.selectAnalysisOption(page, args);
				}
			},
			error: function() {
				alert('Error occured checking for cached output.')
			}
		});
	},


	selectAnalysisOption: function(page, args) {

		var title = '<p>This analysis may take a long time. ' +
			'Do you want to submit the analysis and get an email when it completes?</p>';

		var jobSubmit = '<div id= "kinship_submit">' + title + '</div>';

		jQuery(jobSubmit).appendTo('body');

		jQuery('#kinship_submit')
			.dialog({
				height: 200,
				width: 400,
				modal: true,
				title: "Kinship job submission",
				buttons: {
					OK: {
						text: 'Yes',
						class: 'btn btn-success',
						id: 'queue_job',
						click: function() {
							jQuery(this).dialog("close");

							solGS.submitJob.checkUserLogin(page, args);
						},
					},

					No: {
						text: 'No, I will wait till it completes.',
						class: 'btn btn-warning',
						id: 'no_queue',
						click: function() {
							jQuery(this).dialog("close");

							solGS.kinship.runAnalysis(page, args);
						},
					},

					Cancel: {
						text: 'Cancel',
						class: 'btn btn-info',
						id: 'cancel_queue_info',
						click: function() {
							jQuery(this).dialog("close");
						},
					},
				}
			});

	},

	runAnalysis: function(page, args) {

		var kinArgs = JSON.stringify(args)
		jQuery("#kinship_message")
			.text("Running kinship... please wait...it may take minutes.")
			.show();

		jQuery("#kinship_canvas .multi-spinner-container").show();

		jQuery.ajax({
			type: 'POST',
			dataType: 'json',
			data: {'arguments': kinArgs},
			url: '/kinship/run/analysis/',
			success: function(res) {
				if (res.success) {

					jQuery("#kinship_canvas .multi-spinner-container").hide();
					jQuery("#kinship_message").empty();
					solGS.kinship.getKinshipResult(args);

				} else {
					jQuery("#kinship_message")
						.html('There is no kinship data to plot.')
						.show()
						.fadeOut(8400);

					jQuery("#kinship_canvas .multi-spinner-container").hide();

					jQuery("#run_kinship").show();
				}
			},
			error: function(res) {
				jQuery("#kinship_message")
					.html('Error occured running the kinship.')
					.show()
					.fadeOut(8400);

				jQuery("#kinship_canvas .multi-spinner-container").hide();
			}


		});

	},


	getKinshipResult: function(args) {

		if (args == null) {
			args = this.getKinshipPopDetails();
		}

		jQuery("#kinship_canvas .multi-spinner-container").show();
		jQuery("#kinship_message").html("Retrieving kinship output... please wait...");

		var kinArgs = JSON.stringify(args);
		jQuery.ajax({
			type: 'POST',
			dataType: 'json',
			data: {'arguments': kinArgs},
			url: '/solgs/kinship/result/',
			success: function(res) {

				if (res.data) {
					jQuery("#kinship_message")
						.html("Generating heatmap... please wait...")
						.show();

						var kinCanvas = "#kinship_canvas";
						var kinPlotDivId = "#kinship_plot_" + res.kinship_file_id;
						var links = solGS.kinship.addDowloandLinks(res);
						solGS.heatmap.plot(res.data, kinCanvas, kinPlotDivId , links);

					jQuery("#kinship_canvas .multi-spinner-container").hide();
					jQuery("#kinship_message").empty();

				} else {

					jQuery("#kinship_canvas .multi-spinner-container").hide();
					jQuery("#kinship_message")
						.css({
							"padding-left": '0px'
						})
						.html("This population has no kinship output data.")
						.fadeOut(8400);

					jQuery("#run_kinship").show();
				}
			},
			error: function(res) {
				jQuery("#kinship_canvas .multi-spinner-container").hide();
				jQuery("#kinship_message")
					.css({
						"padding-left": '0px'
					})
					.html("Error occured retreiving the kinship output data.")
					.fadeOut(8400);;

				jQuery("#run_kinship").show();
			}
		});
	},


	// plotKinship: function(data, links) {

	// 	solGS.heatmap.plot(data, '#kinship_canvas', '#kinship_plot', links);

	// },


	addDowloandLinks: function(res) {
		console.log(`adddownloadlinks res: ${JSON.stringify(res)}`)
		var popName = res.kinship_pop_name;
		var kinFileId = res.kinship_file_id;
		var kinshipFile = res.kinship_table_file;

		var aveFile = res.kinship_averages_file;
		var inbreedingFile = res.inbreeding_file;

		var fileNameKinship = kinshipFile.split('/').pop();
		var fileNameAve = aveFile.split('/').pop();
		var fileNameInbreeding = inbreedingFile.split('/').pop();

		kinshipFile = "<a href=\"" + kinshipFile +
			"\" download=" + fileNameKinship + ">Kinship matrix</a>";

		aveFile = "<a href=\"" + aveFile +
			"\" download=" + fileNameAve + ">Average kinship</a>";

		inbreedingFile = "<a href=\"" + inbreedingFile +
			"\" download=" + fileNameInbreeding + ">Inbreeding coefficients</a>";

			var kinDownloadBtn = "download_" + "kinship_plot_" + kinFileId;
			var kinPlotLink = "<a href='#'  onclick='event.preventDefault();' id='" + kinDownloadBtn + "'> plot</a>";

		var links = '<strong>Download:</strong> ';

		if (popName) {
			links = links + popName + ' ';
		}

		links = links + kinshipFile + ' | ' +
			aveFile + ' | ' +
			inbreedingFile + ' | ' + 
			kinPlotLink;

		return links;
	},

	///////
}



jQuery(document).ready(function() {

	jQuery("#run_kinship").click(function() {
		var url = location.pathname;

		var popId;
		var popName;

		if (url.match(/kinship\/analysis/)) {
			solGS.kinship.runKinship();
		} else if (url.match(/breeders\/trial\//)) {
			popId = jQuery("#trial_id").val();
			popName = jQuery("#trial_name").val();
			solGS.kinship.runKinship(popId, popName);
		} else if (url.match(/solgs\/models\/combined\/trials\/|solgs\/traits\/all\/population\//)) {
			popId = jQuery("#training_pop_id").val();
			popName = jQuery("#training_pop_name").val();
			solGS.kinship.runKinship(popId, popName);
		} else {
			solGS.kinship.getKinshipResult();
		}

		jQuery("#run_kinship").hide();
	});

});

jQuery(document).ready(function() {

	var url = location.pathname;

	if (url.match(/kinship\/analysis/)) {
		solGS.selectMenu.populateMenu("kinship_pops", ['accessions', 'trials'], ['accessions', 'trials'])
		var args = solGS.kinship.getKinshipArgsFromUrl();

		if (args.kinship_pop_id) {

			if (args.data_structure) {
				args['kinship_pop_id'] = args.data_structure + '_' + args.kinship_pop_id;
			}
			
			solGS.kinship.checkCachedKinship(url, args);
		}
	}

});

jQuery(document).ready(function() {
	jQuery("#kinship_canvas").on('click' , 'a', function(e) {
		var buttonId = e.target.id;
		var kinPlotId = buttonId.replace(/download_/, '');
		console.log(`buttonID ${buttonId} -- kinplotId: ${kinPlotId}`)
		saveSvgAsPng(document.getElementById("#" + kinPlotId),  kinPlotId + ".png", {scale: 1});	
	});
});

jQuery(document).ready(function() {

	var url = location.pathname;

	if (url.match(/kinship\/analysis/)) {
		jQuery("#kinship_pops_list_select").change(function() {
			var selectedPop = solGS.selectMenu.getSelectedPop('kinship_pops');
			if (selectedPop.selected_id) {
				jQuery("#kinship_pops_go_btn").click(function() {
					solGS.kinship.loadKinshipPops(selectedPop.selected_id, selectedPop.selected_name, selectedPop.data_str);
				});
			}
		});
	}


});