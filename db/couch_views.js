{
  "views": {  
   "by_site_name_and_report_month": {
      "map": "function(doc) { emit(doc['site_name'].trim().split(' ').join('_') + '_' + doc['report_month'].substr(0, 8)) }"
    }
  }
}