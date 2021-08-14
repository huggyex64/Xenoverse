<?php
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
    if ($type=="getRooms"):
        $query = mysqli_query($conn,"SELECT * FROM OnlineBattles");
        while ($row = mysqli_fetch_assoc($query)){
            echo($row["RoomNo"] ."</s>". $row["Debug"] ."</s>"."\r\n");
        }
    elseif ($type=="makeRoom"):
        $query = mysqli_query($conn,"INSERT INTO `my_xntst`.`OnlineBattles` (`RoomNo`, `Debug`) VALUES ('".$_POST["RoomNo"]."', 'This is a newly created Room.')");
        $query = mysqli_query($conn,"SELECT * FROM OnlineBattles");
        while ($row = mysqli_fetch_assoc($query)){
            echo($row["RoomNo"] ."</s>". $row["Debug"] ."</s>"."\r\n");
        }
    elseif ($type=="getDebug"):
        $query = mysqli_query($conn,"SELECT * FROM OnlineBattles WHERE 'RoomNo' = BINARY \"".$_POST["RoomNo"]. "\"");
        while ($row = mysqli_fetch_assoc($query)){
            echo($row["RoomNo"] ."</s>". $row["Debug"] ."</s>"."\r\n");
        }
    else:
        echo("No valid Type given: type ". $type ."\r\n". array_key_first($_POST));
    endif;

    // UPDATE `my_xntst`.`OnlineBattles` SET `Debug` = 'This is a Debug Text.' WHERE `OnlineBattles`.`RoomNo` = 1;
    mysqli_close($conn);
?>