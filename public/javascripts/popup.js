var drugsData = "<table id='malariaDrugs' cellspacing='0px' style='width:80%; left:10%; margin-left: 101px; font-size: 14pt;'>";
var selectMalariaDrug = {};
var selectedDrugID;
var current_selected_drug;

drugsData += "<tr>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>#</th>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>Drug Name</th>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>Frequency</th>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>Duration</th>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>Tabs</th>"
drugsData += "<th style='border-bottom: 1px solid black; padding:8px;'>Action</th></tr>";

uncheckedImg = '/touchscreentoolkit/lib/images/unchecked.png';
checkedImg = '/touchscreentoolkit/lib/images/checked.png';

count = 1
for (var drugID in antiMalariaDrugsHash){
    if (count%2 == 0){
        color = '#FFF'
    }else{
        color = '#FFF' //#CCC
    }
    
    drugName = antiMalariaDrugsHash[drugID]["drug_name"];
    frequency = antiMalariaDrugsHash[drugID]["frequency"];
    duration = antiMalariaDrugsHash[drugID]["duration"];
    tabs = antiMalariaDrugsHash[drugID]["tabs"];
    drugsData += "<tr id='" + drugID + "' drug_name='" + drugName + "' color='" + color + "' onclick = 'highLightSelectedRow(this);' style='cursor: pointer; background-color: " + color + "' row_id='" + drugID + "' >";
    drugsData += "<td style='border-bottom: 1px solid black; padding:8px; font-weight: bold; font-style: italic;'>" + count + ".</td>";
    drugsData += "<td style='border-bottom: 1px solid black; padding:8px; text-align: center;'>" + drugName + "</td>";
    drugsData += "<td style='border-bottom: 1px solid black; text-align: center;'>" + frequency + "</td>";
    drugsData += "<td style='border-bottom: 1px solid black; text-align: center;'>" + duration + "</td>";
    drugsData += "<td style='border-bottom: 1px solid black; text-align: center;'>" + tabs + "</td>";
    drugsData += "<td style='border-bottom: 1px solid black; text-align: center;'><img id='img_" + drugID + "' src='" + uncheckedImg + "'></img></td>";
    drugsData += "</tr>";
    count += 1;
}

drugsData += "</table>"

function antiMalarialPopup(){
    content = document.getElementById('content');
    popupDiv = document.createElement('div');
    popupDiv.className = 'popup-div';
    popupDiv.style.backgroundColor = '#F4F4F4';
    popupDiv.style.border = '2px solid #E0E0E0';
    popupDiv.style.borderRadius = '15px';
    popupDiv.style.height = '522px';
    popupDiv.style.top = '2%';
    popupDiv.style.left = '15%';
    popupDiv.style.marginTop = '-20px';
    popupDiv.style.marginLeft = '-20px';
    popupDiv.style.position = 'absolute';
    popupDiv.style.marginTop = '70px';
    popupDiv.style.width = '1217px';
    popupDiv.style.zIndex = '991';
    content.appendChild(popupDiv);

    popupHeader = document.createElement('div');
    popupHeader.className = 'popup-header';
    popupHeader.innerHTML = 'AntiMalarial Drugs';
    popupHeader.style.borderBottom = '2px solid #7D9EC0';
    popupHeader.style.backgroundColor = '#FFFFFF';
    popupHeader.style.paddingTop = '5px';
    popupHeader.style.borderRadius = '15px 15px 0 0';
    popupHeader.style.fontSize = '14pt';
    popupHeader.style.fontWeight = 'bolder';


    popupDiv.appendChild(popupHeader);
    popupData = document.createElement('div');
    popupData.className = 'popup-data';
    popupData.innerHTML = drugsData;
    popupDiv.appendChild(popupData);
    popupFooter = document.createElement('div');
    popupFooter.className = 'popup-footer';
    popupFooter.style.position = 'absolute';
    popupFooter.style.marginBottom = '60px';

    okayButton = document.createElement('span');
    okayButton.className = 'finishButton';
    okayButton.innerHTML = 'Finish';
    okayButton.style.backgroundImage = 'none';
    okayButton.style.border = '1px solid transparent';
    okayButton.style.borderRadius = '4px';
    okayButton.style.cursor = 'pointer';
    okayButton.style.display = 'inline-block';
    okayButton.style.fontSize = '20px';
    okayButton.style.fontWeight = 'bolder';
    okayButton.style.lineHeight = '1.94857';
    okayButton.style.position = 'absolute';
    okayButton.style.bottom = '10px';
    okayButton.style.padding = '9px 75px';
    okayButton.style.textAlign = 'center';
    okayButton.style.verticalAlign = 'middle';
    okayButton.style.whiteSpace = 'nowrap';
    okayButton.style.backgroundColor = 'green';
    okayButton.style.color = '#fff';
    
    okayButton.onclick = function(){
        hideLibPopup();
    }
    
    popupDiv.appendChild(okayButton);

    //prev article//

    clearButton = document.createElement('span');
    clearButton.className = 'nextButton';
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
    clearButton.style.padding = '9px 75px';
    clearButton.style.textAlign = 'center';
    clearButton.style.verticalAlign = 'middle';
    clearButton.style.whiteSpace = 'nowrap';
    clearButton.style.backgroundColor = '#6495ED';
    clearButton.style.borderColor = '#6495ED';
    clearButton.style.color = '#fff';
    clearButton.style.left = '22.6%';
    clearButton.onclick = function(){
        uncheckRows()
    }

    popupDiv.appendChild(clearButton);

    cancelButton = document.createElement('span');
    cancelButton.className = 'cancelButton';
    cancelButton.innerHTML = 'Cancel';
    cancelButton.style.backgroundImage = 'none';
    cancelButton.style.border = '1px solid transparent';
    cancelButton.style.borderRadius = '4px';
    cancelButton.style.cursor = 'pointer';
    cancelButton.style.display = 'inline-block';
    cancelButton.style.fontSize = '20px';
    cancelButton.style.fontWeight = 'bolder';
    cancelButton.style.lineHeight = '1.94857';
    cancelButton.style.position = 'absolute';
    cancelButton.style.bottom = '10px';
    cancelButton.style.padding = '9px 75px';
    cancelButton.style.textAlign = 'center';
    cancelButton.style.verticalAlign = 'middle';
    cancelButton.style.whiteSpace = 'nowrap';
    cancelButton.style.backgroundColor = '#EE6363';
    cancelButton.style.borderColor = '#EE6363';
    cancelButton.style.color = '#fff';
    cancelButton.style.left = '81%';
    cancelButton.onclick = function(){
        hideLibPopup();
        selectMalariaDrug = {}; //Remove the selected drug
        removeDrugFromGenerics();
    }

    popupDiv.appendChild(cancelButton);

    popupDiv.appendChild(popupFooter);

    popupCover = document.createElement('div');
    popupCover.className = 'popup-cover';
    popupCover.style.position = 'absolute';
    popupCover.style.backgroundColor = 'black';
    popupCover.style.width = '100%';
    popupCover.style.height = '102%';
    popupCover.style.left = '0%';
    popupCover.style.top = '0%';
    popupCover.style.zIndex = '990';
    popupCover.style.opacity = '0.65';
    content.appendChild(popupCover);

    loadPreviousSelectedDrug(); //Preselect previously selected values
}

function highLightSelectedRow(obj){
    rowID = obj.getAttribute('row_id');
    img = document.getElementById('img_' + rowID );
    img_src_array = img.getAttribute("src").split("/");
    src = img_src_array[img_src_array.length - 1];
    if (src == 'unchecked.png'){
        uncheckRows();
        img.src = checkedImg;
        obj.style.backgroundColor = 'lightBlue';
        selectedDrugID = rowID;
        selectMalariaDrug = antiMalariaDrugsHash[parseInt(rowID)];
        current_selected_drug = selectMalariaDrug["drug_name"];
        hackGenericDrugs();
    }else{
        oldColor = obj.getAttribute('color');
        selectMalariaDrug = {}
        obj.style.backgroundColor = oldColor;
        img.src = uncheckedImg;
        removeDrugFromGenerics();

    }

}

function uncheckRows(){
    selectMalariaDrug = {};
    current_selected_drug = null;
    malariaDrugsTable = document.getElementById('malariaDrugs');
    table_rows = malariaDrugsTable.getElementsByTagName('tr');
    for (var i=0; i<=table_rows.length - 1; i++){
        row = table_rows[i];
        if (row.hasAttribute('row_id')){
            rID = row.getAttribute('row_id');
            oldColor = row.getAttribute('color');
            row.style.backgroundColor = oldColor;
            mycheckedImg = document.getElementById('img_' + rID );
            mycheckedImg.src = uncheckedImg;
            d_name = row.getAttribute('drug_name');

            if (selectedGenerics[current_diagnosis]){
                if (selectedGenerics[current_diagnosis][d_name]){
                    delete selectedGenerics[current_diagnosis][d_name];
                }
            }
        }
    }
    
    if (selectedGenerics[current_diagnosis]){
        if (Object.keys(selectedGenerics[current_diagnosis]).length == 0){
            delete selectedGenerics[current_diagnosis] //it has no data
        }
    }
}

function loadPreviousSelectedDrug(){
    if (Object.keys(selectMalariaDrug).length > 0){
        selectedRow = document.getElementById(selectedDrugID);
        selectedRow.style.backgroundColor = 'lightBlue';
        selectedImg = document.getElementById('img_' + selectedDrugID);
        selectedImg.src = checkedImg;
    }
}

function disableEnableFinishButton(){
    finishButton = document.getElementsByClassName("finishButton")[0];
    if (finishButton){
        if (Object.keys(selectMalariaDrug).length == 0){
            finishButton.style.backgroundColor = 'gray';
            finishButton.onclick = function(){

            }
        }else{
            finishButton.style.backgroundColor = 'green';
            finishButton.onclick = function(){
                hideLibPopup();
            }
        }
    }

}

window.setInterval("disableEnableFinishButton()", 200);

function hideLibPopup(){
    popupCover = document.getElementsByClassName("popup-cover")[0];
    popupDiv = document.getElementsByClassName("popup-div")[0];
    if (popupCover) popupCover.parentNode.removeChild(popupCover);
    if (popupDiv) popupDiv.parentNode.removeChild(popupDiv);
}

function hackGenericDrugs(){
    if (!selectedGenerics[current_diagnosis]) selectedGenerics[current_diagnosis] = {};
 
    selectedGenerics[current_diagnosis][current_selected_drug] = {
        "dosage": [selectMalariaDrug["drug_name"], selectMalariaDrug["strength"], selectMalariaDrug["units"]],
        "frequency": selectMalariaDrug["frequency"],
        "duration": selectMalariaDrug["duration"]
    };
}

function removeDrugFromGenerics(){

    if (selectedGenerics[current_diagnosis]){
        if (selectedGenerics[current_diagnosis][current_selected_drug]){
            delete selectedGenerics[current_diagnosis][current_selected_drug];
        }
    }
}