<div id="container">  
    <ul id="keyboard">   
        <li class="letter">1</li>  
        <li class="letter">2</li>  
        <li class="letter">3</li>  
        <li class="letter clearl">4</li>  
        <li class="letter">5</li>  
        <li class="letter">6</li> 
      
        <li class="letter clearl">7</li>  
        <li class="letter ">8</li>  
        <li class="letter">9</li>  
        <li class="letter">0</li>
        <li class="switch">abc</li>  
         <li class="return">retur</li>
         <li class="delete lastitem"><</li>  
    </ul>  
</div>  
  
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>  
<script type="text/javascript" src="js/keyboard.js"></script>



* {  
margin: 0;  
padding: 0;  
}  
body {  
font: 71%/1.5 Verdana, Sans-Serif;  
background: #eee;  
}  
#container {  
margin: 100px auto;  
width: 760px;  
}   
#keyboard {  
margin: 0;  
padding: 0;  
list-style: none;  
}  
    #keyboard li {  
    float: left;  
    margin: 0 5px 5px 0;  
    width: 60px;  
    height: 60px;  
    font-size: 24px;
    line-height: 60px;  
    text-align: center;  
    background: #fff;  
    border: 1px solid #f9f9f9;  
    border-radius: 5px;  
    }  
        .capslock, .tab, .left-shift, .clearl, .switch {  
        clear: left;  
        }  
            #keyboard .tab, #keyboard .delete {  
            width: 70px;  
            }  
            #keyboard .capslock {  
            width: 80px;  
            }  
            #keyboard .return {  
            width: 90px;  
            }  
            #keyboard .left-shift{  
            width: 70px;  
            }  

            #keyboard .switch {
            width: 90px;
            }
            #keyboard .rightright-shift {  
            width: 109px;  
            }  
        .lastitem {  
        margin-right: 0;  
        }  
        .uppercase {  
        text-transform: uppercase;  
        }  
        #keyboard .space {  
        float: left;
        width: 556px;  
        }  
        #keyboard .switch, #keyboard .space, #keyboard .return{
        font-size: 16px;
        }
        .on {  
        display: none;  
        }  
        #keyboard li:hover {  
        position: relative;  
        top: 1px;  
        left: 1px;  
        border-color: #e5e5e5;  
        cursor: pointer;  
        }  

        