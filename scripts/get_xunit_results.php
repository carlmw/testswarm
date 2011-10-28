<?php
$MAX_ATTEMPTS = 20;


$url = $argv[1];
$target_dir = realpath($argv[2]);

// Delete *.xml from target_dir
$d = dir($target_dir);

while($file = $d->read()){
    if(preg_match('/.*\.xml/', $file)){
        unlink($target_dir . '/' . $file);
    }
}

$doc = new DOMDocument();
@$doc->loadHTML(file_get_contents($url));
$xp = new DOMXPath($doc);
$expect = $xp->query("//table[@class='results']//td")->length;
$i = 0;
while(($count = $xp->query("//*[contains(@class, 'notdone')]")->length) > 0 && $i < $MAX_ATTEMPTS){
    @$doc->loadHTML(file_get_contents($url));
    $xp = new DOMXPath($doc);
    
    echo "Waiting for ". $count ." browsers.\n";
    
    $i++;
    sleep(5);
}

$results = $xp->query("//td/a");
$runners = array();
preg_match('/http[s]?:\/\/[^\/]*/', $url, $base_url);
$base_url = $base_url[0];

foreach($results as $result){
    $href = $result->getAttribute('href');
    preg_match('/run_id=(\d*)/', $href, $run_id);
    preg_match('/client_id=(\d*)/', $href, $client_id);
    $result_xml = file_get_contents($base_url . '/?state=xunit&run_id=' . $run_id[1] . '&client_id=' . $client_id[1]);
    
    $file = fopen($target_dir . '/run_' . $run_id[1] . '_' . $client_id[1] . '.xml', 'w');
    fwrite($file, $result_xml);
    fclose($file);
}
echo "DONE!\n";

if($count > 0){
    $missing_xml = fopen($target_dir . '/run_missing_browsers.xml', 'w');
    fwrite($missing_xml, file_get_contents(realpath(dirname($_SERVER['PHP_SELF'])) . '/xunit_browsers_missed.xml'));
    fclose($missing_xml);
    echo "SOME BROWSERS DIDN'T RESPOND\n";
}