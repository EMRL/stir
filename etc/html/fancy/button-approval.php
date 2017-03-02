<?php
session_start();
$run_func = '';

if ($_GET['approval'] == 'yes') { 
    approval(); 
} else { 
    echo '<a href="?approval=yes">Link to myFunction</a>'; 
} 

function approval()  
{ 
// The name of the file that we want to create if it doesn't exist.
$file = 'test.txt';
 
// Use the function is_file to check if the file already exists or not.
if(!is_file($file)){
    // Some simple example content.
    $contents = '#!/bin/bash\n
export TERM=${TERM:-dumb}\n
source ${HOME}/.bash_profile 2>&1\n
source ${HOME}/.keychain/${HOSTNAME}-sh 2>&1\n
deploy --approve ${APP}';
    // Save our content to the file.
    file_put_contents($file, $contents);
}
}  

?>


