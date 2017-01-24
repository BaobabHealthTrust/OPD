function __$(id){
        hideLibPopup();
        return document.getElementById(id);

}
var currentNumericInput;

numericPad = "<table cellspacing='0px' style='width:70%; left:10%; margin-left: 150px; font-size: 14pt;'>";
numericPad += "<tr>"


numericPad += "<td onclick='updateNumericPadInput(1)' style='border-bottom: 1px solid blue; border-right:1px solid blue; padding:6px;'><button style = 'height:100%;width:100%'><span>1</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(2)' style='border-bottom: 1px solid blue; border-right:1px solid blue; padding:6px;'><button style = 'height:100%;width:100%'><span>2</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(3)' style='border-bottom: 1px solid blue; border-right:1px solid blue;padding:6px;'><button style = 'height:100%;width:100%' ><span>3</span></button></td>";
numericPad += "</tr>";

numericPad += "<tr>"
numericPad += "<td onclick='updateNumericPadInput(4)' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px;'><button style = 'height:100%;width:100%'><span>4</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(5)' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px;'><button style = 'height:100%;width:100%'><span>5</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(6)' style='border-bottom: 1px solid blue; border-right:1px solid blue;padding:8px;'><button style = 'height:100%;width:100%'><span>6</span></button></td>";
numericPad += "</tr>";

numericPad += "<tr>"
numericPad += "<td onclick='updateNumericPadInput(7)' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px;'><button style = 'height:100%;width:100%'><span>7</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(8)' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px;'><button style = 'height:100%;width:100%'><span>8</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(9)' style='border-bottom: 1px solid blue; border-right:1px solid blue; padding:8px;'><button style = 'height:100%;width:100%'><span>9</span></button></td>";
numericPad += "</tr>";

numericPad += "<tr>"
numericPad += "<td onclick='updateNumericPadInput(0)' colspan='2' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px; text-align: right;'><button style = 'height:100%;width:100%' ><span>0</span></button></td>";
numericPad += "<td onclick='updateNumericPadInput(\".\")' style='border-bottom: 1px solid blue;border-right:1px solid blue; padding:8px; text-align: center;'><button style = 'height:100%;width:100%'><span>.</span></button></td>";
numericPad += "</tr>";

numericpad += "<tr>"
numericpad += "<td style='border-bottom: 1px solid blue; padding:8px;'><button class= 'clearButton'><span> Clear </span> </button></td>"
numericPad += "</tr>";


numericPad += "</table>";



function numericKepadPopup(obj){
    content = document.getElementById('content');
    popupDiv = document.createElement('div');
    popupDiv.className = 'popup-div';
    popupDiv.style.backgroundColor = '#F4F4F4';
    popupDiv.style.border = '2px solid #004C99';
    popupDiv.style.borderRadius = '15px';
    popupDiv.style.height = '485px';
    popupDiv.style.top = '2%';
    popupDiv.style.left = '23%';
    popupDiv.style.marginTop = '-20px';
    popupDiv.style.marginLeft = '-20px';
    popupDiv.style.position = 'absolute';
    popupDiv.style.marginTop = '50px';
    popupDiv.style.width = '50%';
    popupDiv.style.zIndex = '991';
    content.appendChild(popupDiv);

    popupHeader = document.createElement('div');
    popupHeader.className = 'popup-header';
    popupHeader.innerHTML = "<textarea type='text' class='numeric-input' id='numeric-pad-input' rows='1px' cols ='100px'></textarea></strong><br /><br />";
    popupHeader.style.borderBottom = '2px solid #7D9EC0';
    popupHeader.style.backgroundColor = '#FFFFFF';
    popupHeader.style.paddingTop = '10px';
    popupHeader.style.borderRadius = '15px 15px 0 0';
    popupHeader.style.fontSize = '10pt';
    popupHeader.style.textAlign = 'center';
    popupHeader.style.fontWeight = 'bolder';


    popupDiv.appendChild(popupHeader);
    popupData = document.createElement('div');
    popupData.className = 'popup-data';
    popupData.innerHTML = numericPad;
    popupDiv.appendChild(popupData);
    popupFooter = document.createElement('div');
    popupFooter.className = 'popup-footer';
    popupFooter.style.position = 'absolute';
    popupFooter.style.marginBottom = '60px';

    clearButton = document.createElement('span');
    clearButton.className = '';
    clearButton.innerHTML = 'Clear';
    clearButton.style.backgroundImage = 'none';
    clearButton.style.border = '1px solid transparent';
    clearButton.style.borderRadius = '4px';
    clearButton.style.cursor = 'pointer';
    clearButton.style.display = 'inline-block';
    clearButton.style.fontSize = '20px';
    clearButton.style.fontWeight = 'bolder';
    clearButton.style.lineHeight = '1.94857';
    clearButton.style.position = 'absolute';
    clearButton.style.bottom = '10px';
    clearButton.style.padding = '9px 25px';
    clearButton.style.left = '10px';
    clearButton.style.textAlign = 'center';
    clearButton.style.verticalAlign = 'middle';
    clearButton.style.whiteSpace = 'nowrap';
    clearButton.style.backgroundColor = '#004C99';
    clearButton.style.color = 'white';
    clearButton.onclick = function(){
        clearNumericInput();
    }

    popupDiv.appendChild(clearButton);

    doneButton = document.createElement('span');
    doneButton.className = '';
    doneButton.innerHTML = 'Done';
    doneButton.style.backgroundImage = 'none';
    doneButton.style.border = '1px solid transparent';
    doneButton.style.borderRadius = '4px';
    doneButton.style.cursor = 'pointer';
    doneButton.style.display = 'inline-block';
    doneButton.style.fontSize = '20px';
    doneButton.style.fontWeight = 'bolder';
    doneButton.style.lineHeight = '1.94857';
    doneButton.style.position = 'absolute';
    doneButton.style.bottom = '10px';
    //fastTrackVisitButton.style.right = '0px';
    doneButton.style.padding = '9px 25px';
    doneButton.style.right = '10px';
    doneButton.style.textAlign = 'center';
    doneButton.style.verticalAlign = 'middle';
    doneButton.style.whiteSpace = 'nowrap';
    doneButton.style.backgroundColor = '#004C99';
    doneButton.style.borderColor = '#00688B';
    doneButton.style.color = 'white';
    //assign the current id of the form input 
    id = numericKepadPopup.caller.arguments[0].target.id
    value = numericKepadPopup.caller.arguments[0].target.value
    doneButton.onclick = function(){
        updateNumericInput(id,value);
    }

    popupDiv.appendChild(doneButton);

    popupCover = document.createElement('div');
    popupCover.className = 'popup-cover';
    popupCover.style.position = 'absolute';
    popupCover.style.backgroundColor = 'gray';
    popupCover.style.width = '100%';
    popupCover.style.height = '102%';
    popupCover.style.left = '0%';
    popupCover.style.top = '0%';
    popupCover.style.zIndex = '990';
    popupCover.style.opacity = '0.65';
    content.appendChild(popupCover);
    
}

function hideLibPopup(){
    popupCover = document.getElementsByClassName("popup-cover")[0];
    popupDiv = document.getElementsByClassName("popup-div")[0];
    if (popupCover) popupCover.parentNode.removeChild(popupCover);
    if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);
}


function updateNumericPadInput(value){
    input = document.getElementById('numeric-pad-input');
    if (value == '.'){
        if (input.value.contains('.')){
            if (input.value.length >=1) {input.value += value;}//Avoid decimal point from the beginning or multiple decimals
        }
    }else{
        input.value += value;
    }
    if (parseInt(value) == 0){
        if (input.value == 0){
            input.value = 0 //Avoid things like 000000000000 at the beginning
        }
    }
}

function clearNumericInput(){
    input = document.getElementById('numeric-pad-input');
    input.value = '';
    key = currentNumericInput.getAttribute('key');
    document.getElementById(key).value = ''
}

function updateNumericInput(id,value){
   //get the numeric value from input value
    numericValue = document.getElementById('numeric-pad-input').value;
    if((numericValue==" ") || (numericValue==0)){
        numericValue = value
    }
    __$(id).value = numericValue;

   //assign the entered value on popup to the form
    //obj.getElementsByTagName("span")[0].innerHTML = numericValue;
  
    //close the popup window
    // hideLibPopup(); moved to a this function  __$("text")
    
}