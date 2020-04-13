public class TestRecordsGenerator {
   /**
    * Static method to reset and generate test Lead and Opp records, assigning
    * them Owners that are test Users specifically for this coding challenge.
    * This is designed to fulfill the following coding challenge requirements:
    * * At least 5 different Users as Owners
    * * At least 100 test Lead records
    * * At least 20 test Opp records
    */
    public static void generate() {
        // Reset all generated Lead and Opp records
        Lead[] oldTestLeads = [SELECT Id FROM Lead
                              WHERE Is_Test_Lead__c = TRUE];
        delete oldTestLeads;
        Opportunity[] oldTestOpps = [SELECT Id FROM Opportunity
                                    WHERE Is_Test_Opp__c = TRUE];
        delete oldTestOpps;

        // Fetch all test Users
        User[] testUsers = [SELECT LastName FROM User
                            WHERE Is_Test_User__c = TRUE];

        // Collect all test User Ids
        // My User will get special treatment for testing purposes
        Id[] testUserIds = new Id[] {};
        Id myId;
        for (User testUser : testUsers) {
            if (testUser.LastName == 'Solis') {
                myId = testUser.Id;
            } else {
                testUserIds.add(testUser.Id);
            }
        }

        // Test dates will range from Dec. 1, 2019 - Mar. 31, 2020
        // That gives us ~120 days
        Date limitDate = Date.newInstance(2020, 4, 1);

        // Collection of newly generated Leads
        Lead[] newTestLeads = new Lead[] {};
        Integer counter = 1;
        // ~120 Lead records / 5 test Users ~= 24, for 1 Lead record every day
        Integer divisor = 24;
        for (
                Date currDate = Date.newInstance(2019, 12, 1);
                currDate < limitDate;
                currDate = currDate.addDays(1)) {
            Lead newTestLead = new Lead(
                LastName='Lead ' + counter,
                Company='Company ' + counter,
                CreatedDate=currDate,
                // For excluding Leads not generated
                Is_Test_Lead__c=true
            );
            // Give me half of the Leads
            if (Math.mod(counter, 2) == 0) {
                newTestLead.OwnerId = myId;
            // The rest of the Leads are divided among the other 5 test Users
            } else {
                newTestLead.OwnerId =
                    testOwnerGive(testUserIds, counter, divisor);
            }
            newTestLeads.add(newTestLead);
            counter++;
        }

        // Collection of newly generated Opps
        Opportunity [] newTestOpps = new Opportunity[] {};
        counter = 1;
        // ~24 Opp records / 5 test Users ~= 5, for 1 Opp record every 5 days
        divisor = 5;
        for (
                Date currDate = Date.newInstance(2019, 12, 1);
                currDate < limitDate;
                currDate = currDate.addDays(5)) {
            Opportunity newTestOpp = new Opportunity(
                Name='Opp ' + counter,
                CreatedDate=currDate.addDays(-5),
                CloseDate=currDate,
                Amount=counter * 100,
                // For excluding Opps not generated
                Is_Test_Opp__c=true
            );

            // Half of Opps StageName is 'Prospecting' and half is 'Closed Won'
            if (Math.mod(counter, 2) == 0) {
                newTestOpp.StageName = 'Prospecting';
            } else {
                newTestOpp.StageName = 'Closed Won';
            }

            // Give me 1/3rd of the Opps
            if (Math.mod(counter, 3) == 0) {
                newTestOpp.OwnerId = myId;
            // The rest of the Opps are divided among the other 5 test Users
            } else {
                newTestOpp.OwnerId =
                    testOwnerGive(testUserIds, counter, divisor);
            }
            newTestOpps.add(newTestOpp);
            counter++;
        }

        // Create test records in the database
        insert newTestLeads;
        insert newTestOpps;
    }

   /**
    * Helper static method that gives ownership of generated Lead and Opp
    * records according to a specific design. This method will use a divisor
    * to provide records in date regions. As an example, Jan 1 - 15 records can
    * be owned by test User 1, Jan 16 - 31 records can be owned by test User 2,
    * etc.
    *
    * @param  testUserIds
    *               list of test User Ids; they will be assigned as OwnerIds of
    *               newly generated Lead and Opp records
    * @param  counter
    *               value being divided; increments by 1
    * @param  divisor
    *               divides newly generated Lead and Opp records into
    *               CreatedDate and CloseDate regions respectively
    * @return       Id of one of the test Users
    */
    static Id testOwnerGive(Id[] testUserIds, Integer counter, Integer divisor) {
        // Math.mod is to avoid overflow errors: (counter - 1) will loop back
        // to zero if it exceeds (divisor * testUserIds.size())
        Integer indexLimiter =
            Math.mod(counter - 1, divisor * testUserIds.size());

        return testUserIds[indexLimiter / divisor];
    }
}
