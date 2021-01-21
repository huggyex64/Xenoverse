<?php 
    // db variables
    //weedleteam
    //$servername = '31.11.39.20';
    //$username = 'Sql1501184';
    //$password = '480221o8fn';
    //$dbname = 'Sql1501184_4';
    //altervista
    $servername = 'localhost';
    $username = 'xntst';
    $password = '';
    $dbname = 'my_xntst';

    $conn = mysqli_connect($servername,$username,$password,$dbname);
    // checking connection
    if (!$conn)
        die("failed");
    
    
    $type = $_POST["type"];
    if ($type=="getGifts"):
        $query = mysqli_query($conn,"SELECT * FROM MysteryGift WHERE IDC = BINARY \"".$_POST["code"]. "\"");
        while ($row = mysqli_fetch_assoc($query)){
            echo($row["IDC"] ."</s>". $row["NAME"] ."</s>". 
            $row["LEVEL"]."</s>". $row["SHINY"]."</s>".
             $row["AO"]."</s>". $row["BALL"]."</s>". 
             $row["ITEM"]."</s>". $row["IVS"]."</s>".
              $row["EVS"]."</s>". $row["MOVES"]."</s>".
              $row["ABILITY"]."</s>".$row["NICKNAME"]."</s>".$row["GENDER"]."\r\n");
        }
    elseif ($type=="checkCode"):
    
        $query = mysqli_query($conn,"SELECT * FROM MysteryGift WHERE IDC = BINARY \"".$_POST["code"]. "\"");
        if($result = mysqli_fetch_assoc($query)) {
            echo("true");
        } 
        else 
        {
            echo("false");
        }
    else:
        echo("No valid Type given: type ". $type .", code " .$_POST["code"] . "\r\n". array_key_first($_POST));
    endif;
    mysqli_close($conn);
?>