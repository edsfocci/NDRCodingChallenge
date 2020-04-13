public with sharing class UserControllerHelper {
   /**
    * Static method, providing intermediate processing of Lead and Closed Won
    * Opp records by Owner. Also takes care of additive aggregate calculations,
    * since records are processed sequentially in their respective collections.
    *
    * @param  userMap
    *               Map of Users by User Id
    * @param  leads
    *               Collection of Lead records related to Users in userMap
    * @param  opps
    *               Collection of Closed Won Opp records related to
    *               Users in userMap
    * @return       List of rows of data, mapped by field names, and derived
    *               from Lead and Opp records
    */
    public static Map<Id,Map<String,Object>> intermediateMapByOwner(
            Map<Id,User> userMap, Lead[] leads, Opportunity[] opps) {
        Map<Id,Map<String,Object>> uloMap = new Map<Id,Map<String,Object>>();
        for (Id userId : userMap.keySet()) {
            uloMap.put(userId, new Map<String,Object> {
                'user'          => userMap.get(userId),
                'leads'         => new Lead[] {},
                'opps'          => new Opportunity[] {},
                'totalAmount'   => 0.00
            });
        }

        // Collect all Lead records by Owner
        for (Lead le : leads) {
            Map<String,Object> innerMap = uloMap.get(le.OwnerId);
            ((Lead[]) innerMap.get('leads')).add(le);
        }

        // Collect all Opportunity records by Owner, in CreatedDate order
        for (Opportunity opp : opps) {
            Map<String,Object> innerMap = uloMap.get(opp.OwnerId);
            ((Opportunity[]) innerMap.get('opps')).add(opp);
            innerMap.put('totalAmount',
                ((Decimal) innerMap.get('totalAmount')) + opp.Amount);
        }

        return uloMap;
    }

   /**
    * Static method, providing final processing of Lead and Closed Won
    * Opp records by Owner. Output provides aggregate data only, for use in a
    * report in a custom Lightning component
    *
    * @param  mapByOwner
    *               Mapping of User, Lead, and Opp records + aggregate data
    * @return       List of rows of data, particularly formatted for use in a
    *               data table in the "salesRepPerformanceReport"
    *               custom Lightning component
    */
    public static List<Map<String,Object>> outputMappingDataProcess(
            Map<Id,Map<String,Object>> mapByOwner) {
        List<Map<String,Object>> outputList = new List<Map<String,Object>>();

        for (Id userId : mapByOwner.keySet()) {
            Opportunity[] oppsList =
                (Opportunity[]) mapByOwner.get(userId).get('opps');

            Integer totalLeads =
                ((Lead[]) mapByOwner.get(userId).get('leads')).size();
            Integer totalOpps = oppsList.size();

            // Ensures that only data that can meaningfully contribute to the
            // aggregate calculated data is included in the report.
            // If both totalLeads and totalOpps is zero, the rest of the data
            // can be expected to be either 0 or empty.
            if (totalLeads > 0 || totalOpps > 0) {
                Map<String,Object> dataRow = new Map<String,Object>();

                // User's Name, FirstName and LastName
                dataRow.put(
                    'salesRepName',
                    ((User) mapByOwner.get(userId).get('user')).Name);

                // Record counts
                dataRow.put('totalLeads', totalLeads);
                dataRow.put('totalOpps', totalOpps);

                // Total value of all Closed Won Opps in specified date period
                dataRow.put('totalValue',
                    (Decimal) mapByOwner.get(userId).get('totalAmount'));

                // Handle divide by "totalLeads", when it is zero
                if (totalLeads > 0) {
                    dataRow.put('conversionRate',
                        ((Decimal) totalOpps / totalLeads).setScale(4));
                // Percent of Leads converted to zero or more Opps
                } else {
                    dataRow.put('conversionRate', (Decimal) 0.0000);
                }

                // The latest CreatedDate among Closed Won Opps
                // in the collection
                if (totalOpps > 0) {
                    dataRow.put('latestCreatedDate', oppsList[0].CreatedDate);
                }

                outputList.add(dataRow);
            }
        }

        return outputList;
    }
}
