
use lib 't/lib';

use Test::More 'tests' => 52;

use SGN::Test::WWW::WebDriver;
use SGN::Test::Fixture;

my $f = SGN::Test::Fixture->new();
my $t = SGN::Test::WWW::WebDriver->new();

$t->while_logged_in_as("submitter", sub {
    sleep(1);

    $t->get_ok('/breeders/trial/137');
    sleep(3);

    my $trail_files_onswitch = $t->find_element_ok("trial_upload_files_onswitch",  "id",  "find and open 'trial upload files onswitch' and click");
    $trail_files_onswitch->click();
    sleep(2);

    $t->find_element_ok("upload_datacollector_phenotypes_link", "id", "click on upload_trial_link ")->click();
    sleep(2);

    $t->find_element_ok("upload_phenotype_datacollector_data_level", "id", "find phenotype datacollector data level select")->click();
    sleep(1);

    $t->find_element_ok('//select[@id="upload_phenotype_datacollector_data_level"]/option[@value="plots"]', 'xpath', "Select 'plots' as value of datacollector phenotype data level")->click();

    my $upload_input = $t->find_element_ok("upload_datacollector_phenotype_file_input", "id", "find file input");

    my $filename = $f->config->{basepath}."/t/data/trial/data_collector_upload.xls";
    $t->driver()->upload_file($filename);
    $upload_input->send_keys($filename);
    sleep(1);

    $t->find_element_ok("upload_datacollector_phenotype_submit_verify", "id", "submit spreadsheet file for verification")->click();
    sleep(3);

    my $verify_status = $t->find_element_ok(
        "upload_phenotype_datacollector_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /File data_collector_upload.xls saved in archive./, "Verify the positive validation");
    ok($verify_status =~ /File valid: data_collector_upload.xls./, "Verify the positive validation");
    ok($verify_status =~ /File data successfully parsed./, "Verify the positive validation");
    ok($verify_status =~ /File data verified. Plot names and trait names are valid./, "Verify the positive validation");

    $t->find_element_ok("upload_datacollector_phenotype_submit_store", "id", "submit spreadsheet file for storage")->click();
    sleep(10);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_datacollector_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /File data successfully parsed./, "Verify the positive validation");
    ok($verify_status =~ /All values in your file have been successfully processed!/, "Verify the positive validation");
    ok($verify_status =~ /0 previously stored values overwritten/, "Verify the positive validation");
    ok($verify_status =~ /Metadata saved for archived file./, "Verify the positive validation");
    ok($verify_status =~ /Upload Successfull!/, "Verify the positive validation");

    $t->get_ok('/breeders/trial/137');
    sleep(3);

    my $trail_files_onswitch = $t->find_element_ok("trial_upload_files_onswitch",  "id",  "find and open 'trial upload files onswitch' and click");
    $trail_files_onswitch->click();
    sleep(2);

    $t->find_element_ok("upload_datacollector_phenotypes_link", "id", "click on upload_spreadsheet_link ")->click();
    sleep(2);

    $t->find_element_ok("upload_phenotype_datacollector_data_level", "id", "find phenotype datacollector data level select")->click();
    sleep(1);

    $t->find_element_ok('//select[@id="upload_phenotype_datacollector_data_level"]/option[@value="plots"]', 'xpath', "Select 'plots' as value of datacollector phenotype data level")->click();

    $upload_input = $t->find_element_ok("upload_datacollector_phenotype_file_input", "id", "find file input");
    $filename = $f->config->{basepath}."/t/data/trial/data_collector_upload.xls";
    $t->driver()->upload_file($filename);
    $upload_input->send_keys($filename);
    sleep(1);

    $t->find_element_ok("upload_datacollector_phenotype_submit_verify", "id", "submit spreadsheet file for verification")->click();
    sleep(3);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_datacollector_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /Warnings are shown in yellow. Either fix the file and try again/, "Verify warnings after store validation");
    ok($verify_status =~ /If you continue, by default any new values will be uploaded/, "Verify warnings after store validation");
    ok($verify_status =~ /To overwrite previously stored values instead/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial21 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /trait dry matter content|CO_334:0000092/, "Verify warnings after store validation");
    ok($verify_status =~ /the trait fresh root weight|CO_334:0000012/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial210 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial211 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial212 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial213 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial215 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial22 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial23 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial24 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial25 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial26 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial27 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial28 already has the same value as in your file/, "Verify warnings after store validation");
    ok($verify_status =~ /test_trial29 already has the same value as in your file/, "Verify warnings after store validation");

    $t->find_element_ok("upload_datacollector_phenotype_submit_store", "id", "submit spreadsheet file for storage")->click();
    sleep(10);

    $verify_status = $t->find_element_ok(
        "upload_phenotype_datacollector_verify_status",
        "id", "verify the verification")->get_attribute('innerHTML');

    ok($verify_status =~ /57 previously stored values skipped/, "Verify warnings after store validation");
    ok($verify_status =~ /0 previously stored values overwritten/, "Verify warnings after store validation");
    ok($verify_status =~ /Metadata saved for archived file./, "Verify warnings after store validation");
    ok($verify_status =~ /Upload Successfull!/, "Verify warnings after store validation");

    }
);

$t->driver()->close();
$f->clean_up_db();
done_testing();
