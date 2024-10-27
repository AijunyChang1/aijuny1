<html>
    <head>

    </head>
   <body>
        <button onclick="setCurEndTimeAndPlay(5, 11.48)" type="button">点击播放</button>
        <br>
        <br>
        <audio id="audio1" controls="controls"><source src="D1T02-Wuthering Heights.mp3"></audio>
        <script>
              myAud=document.getElementById("audio1");
              function setCurEndTimeAndPlay(startTime, endTime)
              {
                    myAud.currentTime=startTime;
                    myAud.addEventListener('timeupdate', function(){
                              if (myAud.currentTime>endTime){
                                   pause(); 
                             }
                             
                     }, false);
                    
                    myAud.addEventListener('loadedmetadata', function(){
                                   myAud.play();
                     }, false);
                    myAud.play();
              }
             
        </script>
   </body> 
</html>