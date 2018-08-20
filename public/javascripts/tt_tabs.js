// use 'esversion: 6';

class ttTabsPlugin {
    load(target, items) {
        let content = document.createElement('div');
        content.setAttribute("id", "ttp-tabs-content");
        target.appendChild(content);

        let tabSelectPane = document.createElement('div');
        tabSelectPane.setAttribute("id", "ttp-tabs-select-pane");
        tabSelectPane.setAttribute("class", "ttp-tabs-container");
        content.appendChild(tabSelectPane);

        let tabView = document.createElement('div');
        tabView.setAttribute("id", "tt-tabs-tab-view");
        tabView.setAttribute("class", "ttp-tabs-container");
        content.appendChild(tabView);
        
        let tabPills = document.createElement('ul');
        tabSelectPane.appendChild(tabPills);

        items.forEach((item) => {
            let person = item.person;
            let li = document.createElement("li");
            let ul2 = document.createElement("ul");
            ul2.style.padding = 0;
            let li2 = document.createElement("li");
            li2.style.marginLeft = "10%";
            li2.setAttribute("class", "list2");
            li.setAttribute("id", "duplicate_" + person.id);
            li.setAttribute("onmousedown", "setDOCID('" + person.id + "')");
            li2.setAttribute("id", person.given_name);
            li2.innerHTML= "<strong>DOB:</strong> " + person.birthdate + " <br> <strong>home village:</strong>" + person.home_village;
            // li2.innerHTML = person.home_village;
            li.innerHTML = person.given_name + " " + person.family_name;
            li.addEventListener("click", () => {
                this._clearSelection(tabSelectPane);
                li.classList.add('ttp-selected-item');
                this._displayDuplicate(item, tabView);
            });
            tabPills.appendChild(li);
            li.appendChild(ul2);
            ul2.appendChild(li2);
        });

        // Open first tab
        let tabSelector = tabSelectPane.querySelector("li:first-child");
        tabSelector.classList.add('ttp-selected-item');
        this._displayDuplicate(items[0], tabView);
    }

    _displayDuplicate(duplicate, cell) {
        let {score, person} = duplicate;

        // Clear cell
        cell.innerHTML = '';

        let heading = document.createElement("h1");
        heading.innerHTML = (score * 100) + '% match';
        cell.appendChild(heading);

        let personTable = document.createElement("table");
        cell.appendChild(personTable);
        
        let personTableBody = document.createElement("tbody");
        personTable.appendChild(personTableBody);

        for (let field in person) {
            if (field.match(/_soundex$/) || field.match(/^id$/)) {
                continue;
            }
            this.addRowToTable(personTableBody, field, person);
        }
    }

    _clearSelection(tabSelectPane) {
        let selected = tabSelectPane.getElementsByClassName("ttp-selected-item");
        for (let i = 0; i < selected.length; i++) {
            let tabSelector = selected[i];
            tabSelector.classList.remove("ttp-selected-item");
        }
    }

    addRowToTable(table, field, person) {
        let value = person[field] ;

        let row = document.createElement("tr");
        table.appendChild(row);

    
            let titleCell = document.createElement("td");
            titleCell.innerHTML = field.replace(/_+/, ' ') + ": ";
            row.appendChild(titleCell);
        
        if (field === 'given_name') {
            let valueCell = document.createElement("td");
            // let filename = person.gender.toUpperCase() === "M" ? "male.gif" : "female.gif";
            valueCell.innerHTML = /* '<img src="touchscreentoolkit/lib/images/' + filename + '" />' + */ value;
            row.appendChild(valueCell);
        } else {
            let valueCell = document.createElement("td");
            valueCell.innerHTML = value;
            row.appendChild(valueCell);
        }
    }
}
