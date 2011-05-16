<?php
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
$i = 0;
while($xp->query("//*[contains(@class, 'notdone')]")->length > 0 && $i < 10){
    @$doc->loadHTML(file_get_contents($url));
    $xp = new DOMXPath($doc);
    
    echo "Waiting for ".$xp->query("//*[contains(@class, 'notdone')]")->length." browsers.\n";
    
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
echo 'DONE!';