public with sharing class UserController {
   /**
    * Static method, accessible to Lightning components, that fetches all Lead
    * and Closed Won Opp records, with their CreatedDate and CloseDate
    * respectively within the date range given by input parameters. Data from
    * Opp records are further processed to provide aggregate calculation data,
    * which is included, along with Owner Name and Lead and Opp record counts,
    * in the output List of rows of data by Owner.
    *
    * @param  startDate
    *               Start of a date range for filtering Lead and Opp records
    * @param  endDate
    *               End of a date range for filtering Lead and Opp records
    * @return       List of rows of data, mapped by field names, and derived
    *               from Lead and Opp records
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> fetchSalesRepPerformanceReport(
            Date startDate, Date endDate) {
        // Get all User records that are relevant for this coding challenge
        User[] users = [SELECT Name
                        FROM User
                        WHERE Is_Test_User__c = TRUE];
        Map<Id,User> userMap = new Map<Id,User>(users);

        // Get all Lead records, whose Owners are part of the above Users list,
        // and CreatedDate is between startDate and endDate
        Lead[] leads = [SELECT OwnerId
                        FROM Lead
                        WHERE OwnerId IN :userMap.keySet()
                        AND Is_Test_Lead__c = TRUE
                        AND CreatedDate >= :startDate
                        AND CreatedDate <= :endDate];

        // Get all Opportunity records,
        // whose Owners are part of the above Users list,
        // and ClosDate is between startDate and endDate.
        // Sort by CreatedDate in descending order.
        Opportunity[] opps = [SELECT Amount, CreatedDate, OwnerId
                              FROM Opportunity
                              WHERE OwnerId IN :userMap.keySet()
                              AND StageName = 'Closed Won'
                              AND Is_Test_Opp__c = TRUE
                              AND CloseDate >= :startDate
                              AND CloseDate <= :endDate
                              ORDER BY CreatedDate DESC];

        // Intermediate collection Maps to collect data by Owner
        Map<Id,Map<String,Object>> uloMap =
            UserControllerHelper.intermediateMapByOwner(userMap, leads, opps);

        // Final processing of the data for output
        return UserControllerHelper.outputMappingDataProcess(uloMap);
    }
}
